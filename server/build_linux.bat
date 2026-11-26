@echo off
setlocal
cd /d "%~dp0"

rem Cross-compile a static Linux binary.
rem CGO_ENABLED=0 removes the glibc dependency, so the output runs on
rem CentOS 7+, Debian, Ubuntu and Alpine without extra libraries.
rem Usage: build_linux.bat [amd64^|arm64]
rem This file is intentionally ASCII-only: switching code pages inside a
rem batch file can desynchronise cmd's parser on some Windows builds.

set TARGET_ARCH=%~1
if "%TARGET_ARCH%"=="" set TARGET_ARCH=amd64

set GOOS=linux
set GOARCH=%TARGET_ARCH%
set CGO_ENABLED=0

where go >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Go was not found in PATH. Install Go 1.21+ first.
    goto fail
)

if not exist dist mkdir dist

echo [1/2] Resolving module dependencies...
go mod tidy
if errorlevel 1 goto fail

echo [2/2] Building linux/%TARGET_ARCH% static binary...
go build -trimpath -ldflags "-s -w" -o dist\jade-server .
if errorlevel 1 goto fail

echo.
echo Done: %cd%\dist\jade-server
echo Upload it, then run: chmod +x jade-server ^&^& ./jade-server
exit /b 0

:fail
echo.
echo [FAILED] Build aborted. Check the Go installation and GOPROXY settings.
exit /b 1
