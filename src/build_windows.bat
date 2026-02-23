@echo off
setlocal enabledelayedexpansion
title flo - Build
color 0A

echo.
echo  ========================================
echo    flo - simple budget app
echo    Windows Build Script
echo  ========================================
echo.

:: ── Check Python ─────────────────────────────────────────────────────────────
python --version >nul 2>&1
if errorlevel 1 (
    echo  [ERROR] Python not found.
    echo  Download: https://www.python.org/downloads/
    echo  Check "Add Python to PATH" during install.
    echo.
    pause
    exit /b 1
)
for /f "tokens=*" %%v in ('python --version 2^>^&1') do set PYVER=%%v
echo  [OK] %PYVER%
echo.

:: ── Install build deps ───────────────────────────────────────────────────────
echo  [1/3] Installing pyinstaller and pillow...
python -m pip install pyinstaller pillow --quiet --no-warn-script-location
if errorlevel 1 (
    echo  [ERROR] pip failed. Check internet connection.
    pause
    exit /b 1
)
python -c "import PyInstaller" >nul 2>&1
if errorlevel 1 (
    echo  [ERROR] PyInstaller not importable. Try: pip install pyinstaller
    pause
    exit /b 1
)
echo  [OK] Ready.
echo.

:: ── Generate icon ────────────────────────────────────────────────────────────
cd /d "%~dp0src"
echo  [2/3] Generating icon...
python generate_icon.py
echo.

:: ── Build ────────────────────────────────────────────────────────────────────
echo  [3/3] Building flo.exe (1-3 minutes)...
echo.
python -m PyInstaller flo_win.spec --noconfirm

if errorlevel 1 (
    echo.
    echo  [ERROR] Build failed - see output above.
    pause
    exit /b 1
)
if not exist "dist\flo.exe" (
    echo  [ERROR] dist\flo.exe not found.
    pause
    exit /b 1
)

rmdir /s /q build 2>nul

for %%F in ("dist\flo.exe") do set EXESIZE=%%~zF
set /a EXEMB=%EXESIZE% / 1048576

echo.
echo  ========================================
echo    BUILD COMPLETE  (~%EXEMB% MB)
echo  ========================================
echo.

:: store full path to exe for use after cd changes
set EXE_PATH=%~dp0src\dist\flo.exe

:: ── Install prompt ───────────────────────────────────────────────────────────
echo  Would you like to install flo to Program Files
echo  and create Start Menu + Desktop shortcuts?
echo.
set /p INSTALL="  Install now? (Y/N): "
if /i not "%INSTALL%"=="Y" (
    echo.
    echo  No problem. Run flo any time from:
    echo  %EXE_PATH%
    echo.
    pause
    exit /b 0
)

echo.
echo  Installing flo...
echo  (A UAC prompt will appear - click Yes to allow)
echo.

:: Write a self-contained PowerShell install script to a temp file
:: then run it elevated. This is the most reliable UAC elevation method.
set PS_SCRIPT=%TEMP%\flo_install.ps1

(
echo $src = '%EXE_PATH:\=\\%'
echo $installDir = "$env:ProgramFiles\flo"
echo $startMenu  = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"
echo $desktop    = [Environment]::GetFolderPath('CommonDesktopDirectory'^)
echo.
echo # Create install dir and copy exe
echo New-Item -ItemType Directory -Force -Path $installDir ^| Out-Null
echo Copy-Item -Path $src -Destination "$installDir\flo.exe" -Force
echo.
echo # Helper to create a .lnk shortcut
echo function Make-Shortcut($path, $target^) {
echo     $ws = New-Object -ComObject WScript.Shell
echo     $s  = $ws.CreateShortcut($path^)
echo     $s.TargetPath    = $target
echo     $s.Description   = 'flo - simple budget app'
echo     $s.WorkingDirectory = $installDir
echo     $s.Save(^)
echo }
echo.
echo Make-Shortcut "$startMenu\flo.lnk" "$installDir\flo.exe"
echo Make-Shortcut "$desktop\flo.lnk"   "$installDir\flo.exe"
echo.
echo Write-Host "OK"
) > "%PS_SCRIPT%"

:: Run the script elevated and wait for it to finish
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%PS_SCRIPT%""' -Verb RunAs -Wait"

:: Clean up temp script
del "%PS_SCRIPT%" 2>nul

:: Check if it worked
if exist "%ProgramFiles%\flo\flo.exe" (
    echo.
    echo  ========================================
    echo    flo installed successfully!
    echo  ========================================
    echo.
    echo  Launch from Start Menu or Desktop shortcut.
    echo  Your data:  %%APPDATA%%\flo\data.json
    echo.
) else (
    echo.
    echo  Installation failed or was cancelled.
    echo  You can still run flo directly:
    echo  %EXE_PATH%
    echo.
)
pause
