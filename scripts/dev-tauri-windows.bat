@echo off
setlocal EnableExtensions

rem Run from repository root regardless of caller's current directory.
pushd "%~dp0\.."

set "VSDEVCMD="
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat" (
  set "VSDEVCMD=%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat"
) else if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat" (
  set "VSDEVCMD=%ProgramFiles%\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"
) else if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Professional\Common7\Tools\VsDevCmd.bat" (
  set "VSDEVCMD=%ProgramFiles%\Microsoft Visual Studio\2022\Professional\Common7\Tools\VsDevCmd.bat"
) else if exist "%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\VsDevCmd.bat" (
  set "VSDEVCMD=%ProgramFiles%\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\VsDevCmd.bat"
)

if not defined VSDEVCMD (
  echo [ERROR] VsDevCmd.bat not found. Install Visual Studio 2022 Build Tools with C++ tools.
  popd
  exit /b 1
)

call "%VSDEVCMD%" -no_logo -arch=x64
if errorlevel 1 (
  echo [ERROR] Failed to initialize Visual Studio build environment.
  popd
  exit /b 1
)

if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links" (
  set "PATH=%LOCALAPPDATA%\Microsoft\WinGet\Links;%PATH%"
)
if exist "%USERPROFILE%\.bun\bin" (
  set "PATH=%USERPROFILE%\.bun\bin;%PATH%"
)
if exist "%USERPROFILE%\.cargo\bin" (
  set "PATH=%USERPROFILE%\.cargo\bin;%PATH%"
)
if exist "C:\Program Files\CMake\bin" (
  set "PATH=C:\Program Files\CMake\bin;%PATH%"
)
if exist "%SystemRoot%\System32" (
  set "PATH=%SystemRoot%\System32;%PATH%"
)

set "CMAKE="
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" (
  set "CMAKE=%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"
) else if exist "C:\Program Files\CMake\bin\cmake.exe" (
  set "CMAKE=C:\Program Files\CMake\bin\cmake.exe"
)

set "BUN_EXE="
where bun >nul 2>nul
if not errorlevel 1 (
  for /f "delims=" %%B in ('where bun') do (
    if not defined BUN_EXE set "BUN_EXE=%%B"
  )
)
if not defined BUN_EXE if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links\bun.exe" (
  set "BUN_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Links\bun.exe"
)
if not defined BUN_EXE if exist "%USERPROFILE%\.bun\bin\bun.exe" (
  set "BUN_EXE=%USERPROFILE%\.bun\bin\bun.exe"
)
if not defined BUN_EXE (
  echo [ERROR] bun.exe was not found. Install bun or add it to PATH.
  popd
  exit /b 1
)
set "NODE_EXE="
where node >nul 2>nul
if not errorlevel 1 (
  for /f "delims=" %%N in ('where node') do (
    if not defined NODE_EXE set "NODE_EXE=%%N"
  )
)
if not defined NODE_EXE if exist "%ProgramFiles%\nodejs\node.exe" (
  set "NODE_EXE=%ProgramFiles%\nodejs\node.exe"
)
if not defined NODE_EXE if exist "%ProgramFiles(x86)%\nodejs\node.exe" (
  set "NODE_EXE=%ProgramFiles(x86)%\nodejs\node.exe"
)
if not defined NODE_EXE if exist "%LOCALAPPDATA%\Programs\nodejs\node.exe" (
  set "NODE_EXE=%LOCALAPPDATA%\Programs\nodejs\node.exe"
)
if not defined NODE_EXE (
  echo [ERROR] node.exe was not found. Install Node.js or add it to PATH.
  popd
  exit /b 1
)

set "CARGO_EXE="
where cargo >nul 2>nul
if not errorlevel 1 (
  for /f "delims=" %%C in ('where cargo') do (
    if not defined CARGO_EXE set "CARGO_EXE=%%C"
  )
)
if not defined CARGO_EXE if exist "%USERPROFILE%\.cargo\bin\cargo.exe" (
  set "CARGO_EXE=%USERPROFILE%\.cargo\bin\cargo.exe"
)
if not defined CARGO_EXE (
  echo [ERROR] cargo.exe was not found. Install Rust via rustup or add cargo to PATH.
  popd
  exit /b 1
)

set "RUNTIME_ARCH="
for /f "delims=" %%A in ('"%NODE_EXE%" -p "process.arch" 2^>nul') do (
  if not defined RUNTIME_ARCH set "RUNTIME_ARCH=%%A"
)
if not defined RUNTIME_ARCH (
  for /f "delims=" %%A in ('"%BUN_EXE%" -e "console.log(process.arch)" 2^>nul') do (
    if not defined RUNTIME_ARCH set "RUNTIME_ARCH=%%A"
  )
)
if not defined RUNTIME_ARCH set "RUNTIME_ARCH=arm64"

set "BUN_RUNTIME_ARCH="
for /f "delims=" %%A in ('"%BUN_EXE%" -e "console.log(process.arch)" 2^>nul') do (
  if not defined BUN_RUNTIME_ARCH set "BUN_RUNTIME_ARCH=%%A"
)
if not defined BUN_RUNTIME_ARCH set "BUN_RUNTIME_ARCH=x64"

set "TAURI_CLI_PKG="
if /I "%RUNTIME_ARCH%"=="arm64" (
  set "TAURI_CLI_PKG=@tauri-apps/cli-win32-arm64-msvc"
) else (
  set "TAURI_CLI_PKG=@tauri-apps/cli-win32-x64-msvc"
)

set "TAURI_CLI_DIR=node_modules\@tauri-apps\%TAURI_CLI_PKG:@tauri-apps/=%"
if not exist "%TAURI_CLI_DIR%" (
  echo [INFO] Installing missing %TAURI_CLI_PKG%...
  npm install --no-package-lock --no-save %TAURI_CLI_PKG%@2.9.1
  if errorlevel 1 (
    echo [ERROR] Failed to install %TAURI_CLI_PKG%.
    popd
    exit /b 1
  )
)

set "ROLLUP_PKG="
if /I "%BUN_RUNTIME_ARCH%"=="arm64" (
  set "ROLLUP_PKG=@rollup/rollup-win32-arm64-msvc"
) else (
  set "ROLLUP_PKG=@rollup/rollup-win32-x64-msvc"
)
set "ROLLUP_DIR=node_modules\@rollup\%ROLLUP_PKG:@rollup/=%"

set "ESBUILD_VER="
for /f "delims=" %%V in ('"%NODE_EXE%" -p "require('./node_modules/esbuild/package.json').version" 2^>nul') do (
  if not defined ESBUILD_VER set "ESBUILD_VER=%%V"
)
if not defined ESBUILD_VER set "ESBUILD_VER=0.25.11"

set "ESBUILD_PKG="
if /I "%BUN_RUNTIME_ARCH%"=="arm64" (
  set "ESBUILD_PKG=@esbuild/win32-arm64"
) else (
  set "ESBUILD_PKG=@esbuild/win32-x64"
)
set "ESBUILD_DIR=node_modules\@esbuild\%ESBUILD_PKG:@esbuild/=%"

set "OXIDE_VER="
for /f "delims=" %%V in ('"%NODE_EXE%" -p "require('./node_modules/@tailwindcss/oxide/package.json').version" 2^>nul') do (
  if not defined OXIDE_VER set "OXIDE_VER=%%V"
)
if not defined OXIDE_VER set "OXIDE_VER=4.1.16"

set "OXIDE_PKG="
if /I "%BUN_RUNTIME_ARCH%"=="arm64" (
  set "OXIDE_PKG=@tailwindcss/oxide-win32-arm64-msvc"
) else (
  set "OXIDE_PKG=@tailwindcss/oxide-win32-x64-msvc"
)
set "OXIDE_DIR=node_modules\@tailwindcss\%OXIDE_PKG:@tailwindcss/=%"

set "NEED_FRONTEND_NATIVE="
if not exist "%ROLLUP_DIR%" set "NEED_FRONTEND_NATIVE=1"
if not exist "%ESBUILD_DIR%" set "NEED_FRONTEND_NATIVE=1"
if not exist "%OXIDE_DIR%" set "NEED_FRONTEND_NATIVE=1"
if defined NEED_FRONTEND_NATIVE (
  echo [INFO] Installing frontend native deps...
  npm install --no-save --no-package-lock --force %ROLLUP_PKG% %ESBUILD_PKG%@%ESBUILD_VER% %OXIDE_PKG%@%OXIDE_VER%
  if errorlevel 1 (
    echo [ERROR] Failed to install frontend native deps.
    popd
    exit /b 1
  )
)

rem Clear stale Vite listener on 1420 before launching dev.
for /f "tokens=5" %%P in ('netstat -ano ^| findstr /R /C:":1420 .*LISTENING" 2^>nul') do (
  echo [INFO] Releasing port 1420 PID %%P...
  taskkill /PID %%P /F >nul 2>nul
)

if not exist "logs" mkdir "logs"
set "LOG_FILE=%CD%\logs\tauri-dev.log"
type nul > "%LOG_FILE%"

echo [INFO] Writing output to %LOG_FILE%
echo [INFO] Starting Tauri dev...
set "TAURI_CMD="%NODE_EXE%" node_modules\@tauri-apps\cli\tauri.js dev %*"
set "PS_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if exist "%PS_EXE%" (
  "%PS_EXE%" -NoProfile -ExecutionPolicy Bypass -Command "$cmd = $env:TAURI_CMD; cmd /c $cmd 2>&1 | Tee-Object -FilePath $env:LOG_FILE; exit $LASTEXITCODE"
  set "EXITCODE=%ERRORLEVEL%"
) else (
  echo [WARN] PowerShell not found, using basic logging fallback.
  cmd /c %TAURI_CMD% > "%LOG_FILE%" 2>&1
  type "%LOG_FILE%"
  set "EXITCODE=%ERRORLEVEL%"
)

popd
exit /b %EXITCODE%
