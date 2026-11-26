package main

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"
)

const (
	maxPatchBytes     = 512 << 20 // 单个 .pck 上限 512MB
	patchFormMemory   = 32 << 20  // multipart 表单内存阈值，超出落临时文件
	patchNotesMaxRune = 500
)

// PatchEntry 是 manifest.json 中的单个热更补丁条目。
type PatchEntry struct {
	Rev       int    `json:"rev"`
	Filename  string `json:"filename"`
	URL       string `json:"url"`
	SHA256    string `json:"sha256"`
	Size      int64  `json:"size"`
	Notes     string `json:"notes"`
	CreatedAt int64  `json:"created_at"`
}

type Manifest struct {
	LatestPatchRev int          `json:"latest_patch_rev"`
	Patches        []PatchEntry `json:"patches"`
}

func (a *App) manifestPath() string {
	return filepath.Join(a.dataDir, "manifest.json")
}

// loadManifest 读取清单；文件不存在时生成 latest_patch_rev=0 的默认清单并落盘。
func (a *App) loadManifest() (Manifest, error) {
	m := Manifest{Patches: []PatchEntry{}}
	raw, err := os.ReadFile(a.manifestPath())
	if errors.Is(err, os.ErrNotExist) {
		if err := a.saveManifest(m); err != nil {
			return m, err
		}
		return m, nil
	}
	if err != nil {
		return m, err
	}
	if err := json.Unmarshal(raw, &m); err != nil {
		return m, fmt.Errorf("解析 manifest.json: %w", err)
	}
	if m.Patches == nil {
		m.Patches = []PatchEntry{}
	}
	sort.Slice(m.Patches, func(i, j int) bool { return m.Patches[i].Rev < m.Patches[j].Rev })
	return m, nil
}

// saveManifest 原子更新：先写同目录临时文件，再 rename 覆盖，避免半写入。
func (a *App) saveManifest(m Manifest) error {
	if m.Patches == nil {
		m.Patches = []PatchEntry{}
	}
	sort.Slice(m.Patches, func(i, j int) bool { return m.Patches[i].Rev < m.Patches[j].Rev })
	m.LatestPatchRev = 0
	for _, p := range m.Patches {
		if p.Rev > m.LatestPatchRev {
			m.LatestPatchRev = p.Rev
		}
	}
	raw, err := json.MarshalIndent(m, "", "  ")
	if err != nil {
		return err
	}
	tmp := a.manifestPath() + ".tmp"
	if err := os.WriteFile(tmp, raw, 0o644); err != nil {
		return err
	}
	return os.Rename(tmp, a.manifestPath())
}

// handleVersion 返回增量补丁清单：只含 rev > ?patch_rev 的条目。
func (a *App) handleVersion(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeFail(w, http.StatusMethodNotAllowed, 4050, "仅支持 GET")
		return
	}
	clientRev := 0
	if raw := strings.TrimSpace(r.URL.Query().Get("patch_rev")); raw != "" {
		parsed, err := strconv.Atoi(raw)
		if err != nil || parsed < 0 {
			writeFail(w, http.StatusBadRequest, 4012, "patch_rev 需为非负整数")
			return
		}
		clientRev = parsed
	}
	m, err := a.loadManifest()
	if err != nil {
		writeFail(w, http.StatusInternalServerError, 5012, "读取补丁清单失败")
		return
	}
	patches := make([]PatchEntry, 0, len(m.Patches))
	for _, p := range m.Patches {
		if p.Rev > clientRev {
			patches = append(patches, p)
		}
	}
	writeOK(w, map[string]any{
		"latest_patch_rev": m.LatestPatchRev,
		"patches":          patches,
	})
}

// handlePatchFile 安全分发 patches/ 下的 .pck：严格拒绝路径穿越与非 .pck 后缀。
func (a *App) handlePatchFile(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet && r.Method != http.MethodHead {
		writeFail(w, http.StatusMethodNotAllowed, 4050, "仅支持 GET/HEAD")
		return
	}
	raw := strings.TrimPrefix(r.URL.Path, "/patches/")
	if raw == "" || strings.Contains(raw, "..") || strings.ContainsAny(raw, `/\`) {
		writeFail(w, http.StatusNotFound, 4042, "补丁不存在")
		return
	}
	name := filepath.Base(raw)
	if !strings.HasSuffix(strings.ToLower(name), ".pck") {
		writeFail(w, http.StatusNotFound, 4042, "补丁不存在")
		return
	}
	fullPath := filepath.Join(a.patchesDir, name)
	file, err := os.Open(fullPath)
	if err != nil {
		writeFail(w, http.StatusNotFound, 4042, "补丁不存在")
		return
	}
	defer file.Close()
	info, err := file.Stat()
	if err != nil || info.IsDir() {
		writeFail(w, http.StatusNotFound, 4042, "补丁不存在")
		return
	}
	w.Header().Set("Content-Type", "application/octet-stream")
	w.Header().Set("Content-Disposition", "attachment; filename=\""+name+"\"")
	http.ServeContent(w, r, name, info.ModTime(), file)
}

// handlePublishPatch 管理员一键发版：上传 .pck → 计算 SHA256/大小 → 原子更新清单。
func (a *App) handlePublishPatch(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeFail(w, http.StatusMethodNotAllowed, 4050, "仅支持 POST")
		return
	}
	if !a.requireAdmin(w, r) {
		return
	}

	r.Body = http.MaxBytesReader(w, r.Body, maxPatchBytes+patchFormMemory)
	if err := r.ParseMultipartForm(patchFormMemory); err != nil {
		writeFail(w, http.StatusBadRequest, 4015, "表单解析失败或补丁过大")
		return
	}
	rev, err := strconv.Atoi(strings.TrimSpace(r.FormValue("patch_rev")))
	if err != nil || rev <= 0 {
		writeFail(w, http.StatusBadRequest, 4016, "patch_rev 需为正整数")
		return
	}
	notes := strings.TrimSpace(r.FormValue("notes"))
	if utf8.RuneCountInString(notes) > patchNotesMaxRune {
		writeFail(w, http.StatusBadRequest, 4017, "notes 过长（最多 500 字）")
		return
	}
	file, header, err := r.FormFile("file")
	if err != nil {
		writeFail(w, http.StatusBadRequest, 4018, "缺少文件字段 file")
		return
	}
	defer file.Close()
	if !strings.HasSuffix(strings.ToLower(header.Filename), ".pck") {
		writeFail(w, http.StatusBadRequest, 4019, "仅接受 .pck 补丁文件")
		return
	}

	tmp, err := os.CreateTemp(a.patchesDir, "upload-*.pck")
	if err != nil {
		writeFail(w, http.StatusInternalServerError, 5013, "创建补丁临时文件失败")
		return
	}
	tmpPath := tmp.Name()
	cleanup := true
	defer func() {
		if cleanup {
			os.Remove(tmpPath)
		}
	}()

	hasher := sha256.New()
	written, err := io.Copy(io.MultiWriter(tmp, hasher), io.LimitReader(file, maxPatchBytes+1))
	closeErr := tmp.Close()
	if err != nil || closeErr != nil {
		writeFail(w, http.StatusInternalServerError, 5014, "写入补丁失败")
		return
	}
	if written > maxPatchBytes {
		writeFail(w, http.StatusRequestEntityTooLarge, 4131, "补丁超过 512MB")
		return
	}
	if written == 0 {
		writeFail(w, http.StatusBadRequest, 4020, "补丁内容为空")
		return
	}

	filename := fmt.Sprintf("patch_%d.pck", rev)
	finalPath := filepath.Join(a.patchesDir, filename)
	if err := os.Rename(tmpPath, finalPath); err != nil {
		writeFail(w, http.StatusInternalServerError, 5015, "保存补丁失败")
		return
	}
	cleanup = false

	sum := hex.EncodeToString(hasher.Sum(nil))
	entry := PatchEntry{
		Rev:       rev,
		Filename:  filename,
		URL:       "/patches/" + filename,
		SHA256:    sum,
		Size:      written,
		Notes:     notes,
		CreatedAt: time.Now().Unix(),
	}

	// 与撤回接口共用补丁锁，串行化 manifest 读-改-写，避免并发发版互相覆盖。
	a.patchMu.Lock()
	defer a.patchMu.Unlock()
	m, err := a.loadManifest()
	if err != nil {
		writeFail(w, http.StatusInternalServerError, 5012, "读取补丁清单失败")
		return
	}
	replaced := make([]PatchEntry, 0, len(m.Patches)+1)
	for _, p := range m.Patches {
		if p.Rev != rev {
			replaced = append(replaced, p)
		}
	}
	m.Patches = append(replaced, entry)
	if err := a.saveManifest(m); err != nil {
		writeFail(w, http.StatusInternalServerError, 5016, "更新补丁清单失败")
		return
	}
	writeOK(w, entry)
}

// handleAdminPatchDelete 管理端撤回补丁：POST body {"patch_rev": 正整数}。
func (a *App) handleAdminPatchDelete(w http.ResponseWriter, r *http.Request) {
	if !a.requireAdmin(w, r) {
		return
	}
	if r.Method != http.MethodPost {
		writeFail(w, http.StatusMethodNotAllowed, 4050, "仅支持 POST")
		return
	}
	var req struct {
		PatchRev int `json:"patch_rev"`
	}
	if err := decodeJSON(w, r, requestJSONLimit, &req); err != nil {
		writeFail(w, http.StatusBadRequest, 4000, "请求体格式不正确")
		return
	}
	a.deletePatch(w, req.PatchRev)
}

// handleAdminPatchDeleteByPath 兼容 DELETE /api/admin/patches/{rev}。
func (a *App) handleAdminPatchDeleteByPath(w http.ResponseWriter, r *http.Request) {
	if !a.requireAdmin(w, r) {
		return
	}
	if r.Method != http.MethodDelete {
		writeFail(w, http.StatusMethodNotAllowed, 4050, "仅支持 DELETE")
		return
	}
	raw := strings.Trim(strings.TrimPrefix(r.URL.Path, "/api/admin/patches/"), "/")
	rev, err := strconv.Atoi(raw)
	if err != nil {
		writeFail(w, http.StatusBadRequest, 4005, "补丁版本号不正确")
		return
	}
	a.deletePatch(w, rev)
}

func (a *App) deletePatch(w http.ResponseWriter, rev int) {
	if rev <= 0 {
		writeFail(w, http.StatusBadRequest, 4016, "patch_rev 需为正整数")
		return
	}
	a.patchMu.Lock()
	defer a.patchMu.Unlock()

	m, err := a.loadManifest()
	if err != nil {
		writeFail(w, http.StatusInternalServerError, 5012, "读取补丁清单失败")
		return
	}
	found := -1
	for i, p := range m.Patches {
		if p.Rev == rev {
			found = i
			break
		}
	}
	if found < 0 {
		writeFail(w, http.StatusNotFound, 4042, "补丁不存在")
		return
	}

	remaining := make([]PatchEntry, 0, len(m.Patches)-1)
	remaining = append(remaining, m.Patches[:found]...)
	remaining = append(remaining, m.Patches[found+1:]...)
	// saveManifest 按值传参：此处先本地重算，保证落盘与接口响应使用同一新值；空清单归 0。
	m.Patches = remaining
	m.LatestPatchRev = 0
	for _, p := range m.Patches {
		if p.Rev > m.LatestPatchRev {
			m.LatestPatchRev = p.Rev
		}
	}
	if err := a.saveManifest(m); err != nil {
		writeFail(w, http.StatusInternalServerError, 5016, "更新补丁清单失败")
		return
	}

	// 删除对应 .pck；文件已不存在时静默忽略。
	filePath := filepath.Join(a.patchesDir, fmt.Sprintf("patch_%d.pck", rev))
	if err := os.Remove(filePath); err != nil && !errors.Is(err, os.ErrNotExist) {
		writeFail(w, http.StatusInternalServerError, 5017, "删除补丁文件失败")
		return
	}
	writeOK(w, map[string]any{
		"deleted_rev":      rev,
		"latest_patch_rev": m.LatestPatchRev,
	})
}
