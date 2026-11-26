extends Node
## 图标渲染引擎：以 IconSvgPack 为唯一图源，负责配色注入、栅格化与缓存。
## 零外部图片依赖；scale = 2.0 保证高 DPI 锐利。

## 浅色宣纸底适配：主线条用深松烟墨，点缀用国画矿物质色
const DEFAULT_PRIMARY: String = "#2C2824"
const DEFAULT_ACCENT: String = "#2A6F62"
## 48×48 画布输出 192×192 纹理，2K/3x 屏放大到战斗舞台依然锐利
const SVG_RASTER_SCALE: float = 4.0

## 五行点缀色（矿物颜料，浅底高对比）
const ELEMENT_ACCENT: Dictionary = {
	"NONE": "#8C8375",
	"WOOD": "#2E7D5B",
	"FIRE": "#C2432D",
	"EARTH": "#9A6B2F",
	"METAL": "#52606D",
	"WATER": "#2A6B8C",
}

## 品质配色：凡品 / 精良 / 极品
const QUALITY_COLORS: Array = [
	{"primary": "#4A443B", "accent": "#8C8375"},
	{"primary": "#2E7D5B", "accent": "#2A6F62"},
	{"primary": "#A87424", "accent": "#8A5A16"},
]

## 作物专属点缀色（让四块田一眼分辨品种）
const CROP_ACCENTS: Dictionary = {
	"item_qingye": "#2E7D5B",
	"item_ninglu": "#2A6B8C",
	"item_spirit_berry": "#A87424",
	"item_ziyun": "#6B5A8E",
	"item_chiyan": "#C2432D",
}

## IconSvgPack.ITEM_KEY_MAP 之外的补漏
const ITEM_KEY_EXTRA: Dictionary = {
	"item_spirit_stone": "item_spirit_stone",
}

## 渡劫阵盘：UI 专用 200×200 模板，明确归类，不参与物品图标映射与图鉴统计
const UI_RING_TEMPLATES: Array[String] = [
	"tribulation_ring_outer", "tribulation_ring_inner",
]

## 历史造型 key -> 新图源 key（保证旧调用点无需改动）
const KEY_ALIASES: Dictionary = {
	"ui_default": "default_jade",
	"ui_skill": "default_jade",
	"it_leaf": "item_qingye",
	"it_flower": "item_ninglu",
	"it_lingzhi": "item_ziyun",
	"it_flameleaf": "item_chiyan",
	"it_log": "item_wood",
	"it_ore": "item_ore",
	"it_pill": "item_pill",
	"it_bottle": "item_heal_pill",
	"it_fruit": "item_spirit_berry",
	"it_core": "item_beast_core",
	"it_stone": "item_spirit_stone",
	"it_sword": "equip_sword",
	"it_robe": "equip_robe",
	"it_shield_talisman": "item_shield_talisman",
	"it_thunder_talisman": "item_thunder_talisman",
	"it_paper": "item_shield_talisman",
	"it_hoe": "tool_hoe",
	"it_axe": "tool_axe",
	"it_pick": "tool_pick",
	"it_furnace": "gear_furnace",
	"it_hammer": "gear_hammer",
	"it_mat": "gear_mat",
	"it_bell": "gear_bell",
	"it_brush": "gear_brush",
	"it_array": "gear_array",
	"it_seed": "item_seed",
	# v4 高阶妖兽已全部升级为独立模板（enemy_<id>），不再走家族别名
}

var _cache: Dictionary = {}
var _templates: Dictionary = {}
var _item_key_map: Dictionary = {}

const NAV_ICON_PATHS: Dictionary = {
	"craft": "res://assets/icons/nav/nav_craft.png",
	"farm": "res://assets/icons/nav/nav_farm.png",
	"realm": "res://assets/icons/nav/nav_realm.png",
	"market": "res://assets/icons/nav/nav_market.png",
	"bag": "res://assets/icons/nav/nav_bag.png",
}

## 底部导航单图视觉补偿：五张 128×128 画布的有效内容占比差异极大
## （realm 50×67  vs  market 121×126）。载入时统一按 alpha 包围盒裁掉透明留白，
## 等比缩放后高度已齐平；这里只对「近方形轮廓」再收一点点，避免同高下显得体量偏大。
const NAV_ICON_OPTICAL_SCALE: Dictionary = {
	"market": 0.96,
	"bag": 0.98,
}


func _ready() -> void:
	rebuild_cache()


## PCK 热更后重建：清空纹理缓存，CACHE_MODE_REPLACE 重读 IconSvgPack，
## 从脚本常量表取最新 TEMPLATES / ITEM_KEY_MAP，确保新增图标立即生效。
func rebuild_cache() -> void:
	_cache.clear()
	var constants := _load_pack_constants()
	var templates_value: Variant = constants.get("TEMPLATES", {})
	if typeof(templates_value) == TYPE_DICTIONARY \
			and not (templates_value as Dictionary).is_empty():
		_templates = templates_value
	var key_map_value: Variant = constants.get("ITEM_KEY_MAP", {})
	if typeof(key_map_value) == TYPE_DICTIONARY:
		_item_key_map = key_map_value
	if _templates.is_empty():
		_templates = IconSvgPack.TEMPLATES
	if _item_key_map.is_empty():
		_item_key_map = IconSvgPack.ITEM_KEY_MAP


## 从 PCK 已覆盖的源文件重新编译 IconSvgPack，读取其常量表。
## 带 class_name 的脚本不能直接 ResourceLoader 替换（会与全局类冲突），故剥离后编译。
func _load_pack_constants() -> Dictionary:
	var file := FileAccess.open("res://core/resources/IconSvgPack.gd", FileAccess.READ)
	if file != null:
		var source := file.get_as_text()
		file.close()
		source = source.replace("class_name IconSvgPack\r\n", "")
		source = source.replace("class_name IconSvgPack\n", "")
		var fresh := GDScript.new()
		fresh.source_code = source
		if fresh.reload() == OK:
			return fresh.get_script_constant_map()
	var pack_script: Script = ResourceLoader.load(
		"res://core/resources/IconSvgPack.gd", "Script",
		ResourceLoader.CACHE_MODE_REPLACE) as Script
	if pack_script != null:
		return pack_script.get_script_constant_map()
	return {}


# ---------------------------------------------------------------- 对外接口

func get_icon(icon_key: String, primary_hex: String = DEFAULT_PRIMARY,
		accent_hex: String = DEFAULT_ACCENT) -> ImageTexture:
	var key := _resolve_key(icon_key)
	var cache_key := "%s|%s|%s" % [key, primary_hex, accent_hex]
	var cached: Variant = _cache.get(cache_key, null)
	if cached != null:
		return cached as ImageTexture
	var svg := String(_templates[key]).replace("{C1}", primary_hex).replace("{C2}", accent_hex)
	var image := Image.new()
	var err := image.load_svg_from_string(svg, SVG_RASTER_SCALE)
	if err != OK:
		# 兜底：极简玉简图，保证永不返回 null
		image = Image.create(192, 192, false, Image.FORMAT_RGBA8)
		image.fill(Color(DEFAULT_PRIMARY))
	# Mipmap：同一份纹理缩到 22×22 也不锯齿
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	_cache[cache_key] = texture
	return texture


## 渡劫阵盘专用：按目标显示尺寸栅格化 200×200 模板（不走 48×48 的 SVG_RASTER_SCALE）
func get_ui_ring_texture(template_key: String, primary_hex: String, accent_hex: String,
		size_px: int) -> ImageTexture:
	if not UI_RING_TEMPLATES.has(template_key) or not _templates.has(template_key):
		return null
	var cache_key := "ring|%s|%s|%s|%d" % [template_key, primary_hex, accent_hex, size_px]
	var cached: Variant = _cache.get(cache_key, null)
	if cached != null:
		return cached as ImageTexture
	var svg := String(_templates[template_key]).replace("{C1}", primary_hex).replace("{C2}", accent_hex)
	var image := Image.new()
	if image.load_svg_from_string(svg, float(size_px) / 200.0) != OK:
		push_warning("渡劫阵盘 SVG 解析失败：%s" % template_key)
		return null
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	_cache[cache_key] = texture
	return texture


## 品质后缀 -> 品质等级（品质变体可用独立物品 ID 表示）
const QUALITY_SUFFIXES: Array = [["_fine", 1], ["_epic", 2]]


func _split_quality(item_id: String) -> Dictionary:
	for entry in QUALITY_SUFFIXES:
		var suffix := String(entry[0])
		if item_id.ends_with(suffix):
			return {
				"id": item_id.substr(0, item_id.length() - suffix.length()),
				"quality": int(entry[1]),
			}
	return {"id": item_id, "quality": 0}


## quality = -1 时自动从 `_fine` / `_epic` 后缀推断
func get_item_icon(item_id: String, quality: int = -1) -> ImageTexture:
	var split := _split_quality(item_id)
	var base_id := String(split["id"])
	if quality < 0:
		quality = int(split["quality"])
	quality = clampi(quality, 0, 2)

	var shape := _item_shape(base_id)
	var item := DataRegistry.get_item(base_id)
	if item == null:
		item = DataRegistry.get_item(item_id)

	var primary := DEFAULT_PRIMARY
	var accent := DEFAULT_ACCENT
	if quality > 0:
		var palette: Dictionary = QUALITY_COLORS[quality]
		primary = String(palette["primary"])
		accent = String(palette["accent"])
	elif item != null:
		accent = String(ELEMENT_ACCENT.get(_element_name(item.element), DEFAULT_ACCENT))
	return get_icon(shape, primary, accent)


## 自检 / 调试：返回某物品最终命中的模板键
func get_item_key(item_id: String) -> String:
	var split := _split_quality(item_id)
	return _item_shape(String(split["id"]))


## 仙坊阁商品图标：走 ITEM_KEY_MAP，按分类给点缀色
func get_shop_icon(upgrade: ShopUpgradeData) -> ImageTexture:
	if upgrade == null:
		return get_icon("default_jade")
	var accent := DEFAULT_ACCENT
	match upgrade.category:
		"farm":
			accent = "#2E7D5B"
		"seed":
			accent = "#A87424"
		"gear":
			accent = "#2A6F62"
	return get_icon(_item_shape(upgrade.id), DEFAULT_PRIMARY, accent)


func get_skill_icon(skill_id: String) -> ImageTexture:
	var accent := DEFAULT_ACCENT
	var meta := DataRegistry.get_skill_meta(skill_id)
	if not meta.is_empty():
		# 暗色技能色在宣纸底上压深一档，保证线条清晰
		var skill_color: Color = meta.get("color", Color("#2A6F62"))
		accent = "#%s" % skill_color.darkened(0.22).to_html(false)
	return get_icon("skill_%s" % skill_id, DEFAULT_PRIMARY, accent)


func get_enemy_icon(enemy_id: String) -> ImageTexture:
	var enemy := DataRegistry.get_enemy(enemy_id)
	# 动态塔敌等带 icon_id 时按图标源解析（全秘境妖兽造型轮换）
	var icon_key := enemy_id
	if enemy != null and enemy.icon_id != "":
		icon_key = enemy.icon_id
	var src := DataRegistry.get_enemy(icon_key)
	var accent := "#B83B2A"
	if (enemy != null and enemy.is_boss) or (src != null and src.is_boss):
		accent = "#A87424"
	return get_icon(icon_key, DEFAULT_PRIMARY, accent)


func get_ui_icon(ui_key: String) -> ImageTexture:
	return get_icon("ui_%s" % ui_key)


## 道藏功法 21 枚独立精绘模板的水墨双色（{C1} 主线条 / {C2} 点缀）：
## 木/灵植 黛玉青+暖金 · 火/丹道 朱砂褐+鎏金 · 金/剑意 玄铁青+寒芒金
## 土/炼体 沉金褐+琥珀金 · 雷/星辰/幽冥/混沌/太虚 靛青玄紫+星辉金
const TECH_GRADE_COLORS := {
	"tech_changchun": ["#2F6B52", "#C79A4B"],
	"tech_baicao": ["#2F6B52", "#C79A4B"],
	"tech_yinhe_guangai": ["#2F6B52", "#C79A4B"],
	"tech_lihuo": ["#9A3B2E", "#C9A227"],
	"tech_zaohua_dan": ["#9A3B2E", "#C9A227"],
	"tech_gengjin": ["#3E5A6B", "#D9C47A"],
	"tech_taichu": ["#3E5A6B", "#D9C47A"],
	"tech_xinghe_jian": ["#3E5A6B", "#D9C47A"],
	"tech_hongmeng_zhuxian": ["#3E5A6B", "#D9C47A"],
	"tech_xuangui": ["#7A5A2E", "#D89A3E"],
	"tech_jiuyou_bumie": ["#7A5A2E", "#D89A3E"],
	"tech_longxue": ["#7A5A2E", "#D89A3E"],
	"tech_hunyuan_yiqi": ["#7A5A2E", "#D89A3E"],
	"tech_jiuxiao": ["#4A3B8C", "#E4C36B"],
	"tech_xingchen_lianshen": ["#4A3B8C", "#E4C36B"],
	"tech_youming": ["#4A3B8C", "#E4C36B"],
	"tech_hundun_kaitian": ["#4A3B8C", "#E4C36B"],
	"tech_taixu_bijie": ["#4A3B8C", "#E4C36B"],
	"tech_taixu_zhengdao": ["#4A3B8C", "#E4C36B"],
	"tech_zhoutian_tuna": ["#4A3B8C", "#E4C36B"],
	"tech_zhoutian_xingdou": ["#4A3B8C", "#E4C36B"],
}


## 吐纳功课 8 枚进阶模板的双色（素砚灰 → 翠竹青 → 沧溟蓝 → 紫霞绛 → 赤金辉）
const ACT_GRADE_COLORS := {
	"act_meditate_qi": ["#4A443D", "#7A7165"],
	"act_meditate_foundation": ["#1E5B45", "#2A8B64"],
	"act_meditate_core": ["#1E548C", "#B87D28"],
	"act_meditate_nascent": ["#1B5B9A", "#3D8AD4"],
	"act_meditate_spirit": ["#6C2D8C", "#9B51B8"],
	"act_meditate_void": ["#582A82", "#C2882A"],
	"act_meditate_unity": ["#8F4812", "#D47A1E"],
	"act_meditate_mahayana": ["#A34B0D", "#E09628"],
}


## 吐纳动作专属图标：按 act_meditate_* 键取双色栅格化
func get_action_icon(icon_key: String) -> ImageTexture:
	var pair: Variant = ACT_GRADE_COLORS.get(icon_key)
	if pair is Array:
		return get_icon(icon_key, String((pair as Array)[0]), String((pair as Array)[1]))
	return get_icon(icon_key)


## 藏经阁功法图标：21 枚独立模板走双色映射，旧 tech_wood/sword/shield 兜底
func get_technique_icon(icon_key: String, accent_hex: String = "") -> ImageTexture:
	var pair: Variant = TECH_GRADE_COLORS.get(icon_key)
	if pair is Array:
		return get_icon(icon_key, String((pair as Array)[0]),
			accent_hex if accent_hex != "" else String((pair as Array)[1]))
	var accent := accent_hex
	if accent == "":
		match icon_key:
			"tech_sword":
				accent = "#A87424"
			"tech_shield":
				accent = "#2A6B8C"
			_:
				accent = "#2E7D5B"
	return get_icon(icon_key, DEFAULT_PRIMARY, accent)


## 把 PNG / 已光栅化的 SVG 统一归一化到固定正方形画布：
## 先按非透明包围盒裁边，再等比缩放到主体最大边，四周留白并居中。
## source_key 由调用方传入稳定图标键；纹理实例 ID 参与缓存，避免同名异色互相覆盖。
func get_normalized_icon(source_key: String, source: Texture2D,
		canvas_size: int = 48, padding: int = 4) -> Texture2D:
	if source == null:
		return null
	var canvas := maxi(16, canvas_size)
	var pad := clampi(padding, 0, canvas / 2 - 1)
	var cache_key := "normalized|%s|%d|%d|%d" % [
		source_key, source.get_instance_id(), canvas, pad]
	var cached: Variant = _cache.get(cache_key, null)
	if cached != null:
		return cached as Texture2D
	var image := source.get_image()
	if image == null or image.get_width() <= 0 or image.get_height() <= 0:
		_cache[cache_key] = source
		return source
	if image.is_compressed() and image.decompress() != OK:
		_cache[cache_key] = source
		return source
	var used := image.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		_cache[cache_key] = source
		return source
	var cropped: Image = image.get_region(used)
	if cropped == null or cropped.get_width() <= 0 or cropped.get_height() <= 0:
		_cache[cache_key] = source
		return source
	var max_side := canvas - pad * 2
	var scale := minf(float(max_side) / float(cropped.get_width()),
		float(max_side) / float(cropped.get_height()))
	var target_w := maxi(1, int(round(float(cropped.get_width()) * scale)))
	var target_h := maxi(1, int(round(float(cropped.get_height()) * scale)))
	if target_w != cropped.get_width() or target_h != cropped.get_height():
		cropped.resize(target_w, target_h)
	var normalized := Image.create(canvas, canvas, false, Image.FORMAT_RGBA8)
	normalized.fill(Color(0, 0, 0, 0))
	normalized.blend_rect(cropped, Rect2i(Vector2i.ZERO, Vector2i(target_w, target_h)),
		Vector2i((canvas - target_w) / 2, (canvas - target_h) / 2))
	normalized.generate_mipmaps()
	var texture := ImageTexture.create_from_image(normalized)
	_cache[cache_key] = texture
	return texture


func get_nav_icon(nav_key: String) -> Texture2D:
	var key := nav_key
	if key == "combat":
		key = "realm"
	elif key == "shop":
		key = "market"
	var path := String(NAV_ICON_PATHS.get(key, ""))
	if path != "" and ResourceLoader.exists(path):
		var cache_key := "nav_png|" + key
		var cached: Variant = _cache.get(cache_key, null)
		if cached != null:
			return cached as Texture2D
		var loaded: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
		if loaded is Texture2D:
			var trimmed := _trim_nav_canvas(loaded as Texture2D)
			_cache[cache_key] = trimmed
			return trimmed
	return get_icon("nav_%s" % key, DEFAULT_PRIMARY, DEFAULT_ACCENT)


## 单图视觉补偿系数：默认 1.0，仅对近方形轮廓做 ≤4% 的收笔
func get_nav_icon_scale(nav_key: String) -> float:
	return float(NAV_ICON_OPTICAL_SCALE.get(nav_key, 1.0))


## 导航 PNG 的透明留白占比不同，直接用原图等比缩放会让五枚图标大小不一。
## 先按 alpha 包围盒裁边（四周留 1px 防线性过滤切掉笔锋），再做等比缩放。
func _trim_nav_canvas(texture: Texture2D) -> Texture2D:
	if texture == null:
		return texture
	var image := texture.get_image()
	if image == null:
		return texture
	if image.is_compressed() and image.decompress() != OK:
		return texture
	var used := image.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		return texture
	var bounds := Rect2i(Vector2i.ZERO, image.get_size())
	var rect := used.grow(1).intersection(bounds)
	if rect.size.x <= 0 or rect.size.y <= 0:
		return texture
	var cropped: Image = image.get_region(rect)
	if cropped == null or cropped.get_width() <= 0 or cropped.get_height() <= 0:
		return texture
	cropped.generate_mipmaps()
	return ImageTexture.create_from_image(cropped)


func get_farm_icon(stage: int, crop_id: String = "") -> ImageTexture:
	if stage <= 0:
		return get_icon("farm_empty", "#8C8375", "#B0A695")
	var crop_accent := String(CROP_ACCENTS.get(crop_id, ""))
	var accent := crop_accent
	if accent == "":
		accent = "#A87424" if stage == 3 else "#2E7D5B"
	return get_icon("farm_stage%d" % stage, DEFAULT_PRIMARY, accent)


## 未开垦灵田：荒石杂草造型，与「空闲」的等距「田」字灵畦明确区分。
## 沿用空闲地块的石灰点缀色，保证四个地块同处一行时色调统一。
func get_farm_locked_icon() -> ImageTexture:
	return get_icon("farm_locked", "#8C8375", "#B0A695")


## 灵田三阶段生长图：sprout / growing / mature
func get_farm_growth_icon(stage_key: String, crop_id: String = "") -> ImageTexture:
	var accent := String(CROP_ACCENTS.get(crop_id, ""))
	if accent == "":
		accent = "#A87424" if stage_key == "farm_stage_mature" else "#2E7D5B"
	return get_icon(stage_key, DEFAULT_PRIMARY, accent)


func get_quality_icon(item_id: String, quality: int) -> ImageTexture:
	return get_item_icon(item_id, quality)


func get_template_count() -> int:
	return _templates.size()


func clear_cache() -> void:
	_cache.clear()


func get_cache_size() -> int:
	return _cache.size()


# ---------------------------------------------------------------- 内部

func _resolve_key(icon_key: String) -> String:
	if _templates.has(icon_key):
		return icon_key
	var alias := String(KEY_ALIASES.get(icon_key, ""))
	if alias != "" and _templates.has(alias):
		return alias
	return "default_jade"


func _item_shape(item_id: String) -> String:
	if _item_key_map.has(item_id):
		return String(_item_key_map[item_id])
	if ITEM_KEY_EXTRA.has(item_id):
		return String(ITEM_KEY_EXTRA[item_id])
	var item := DataRegistry.get_item(item_id)
	if item == null:
		return "default_jade"
	match item.category:
		ItemData.Category.EQUIPMENT:
			return "equip_sword" if item.equip_slot == "weapon" else "equip_robe"
		ItemData.Category.CONSUMABLE:
			if item.heal_amount > 0:
				return "item_heal_pill"
			if item.ward_ratio > 0.0:
				return "item_shield_talisman"
			return "item_pill"
		_:
			return "item_qingye"


func _element_name(element: int) -> String:
	match element:
		ItemData.Element.WOOD:
			return "WOOD"
		ItemData.Element.FIRE:
			return "FIRE"
		ItemData.Element.EARTH:
			return "EARTH"
		ItemData.Element.METAL:
			return "METAL"
		ItemData.Element.WATER:
			return "WATER"
		_:
			return "NONE"
