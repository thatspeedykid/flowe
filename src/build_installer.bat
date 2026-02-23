@echo off
setlocal enabledelayedexpansion
title flo - Build Installer
color 0A
cd /d "%~dp0"

echo.
echo  ========================================
echo    flo - Build Installer (flo_setup.exe)
echo  ========================================
echo.

:: ── Check flo.exe was built first ────────────────────────────────────────────
if not exist "src\dist\flo.exe" (
    echo  [ERROR] src\dist\flo.exe not found.
    echo  Run build_windows.bat first, then run this.
    echo.
    pause
    exit /b 1
)
echo  [OK] flo.exe found.
echo.

:: ── Find Inno Setup ──────────────────────────────────────────────────────────
set ISCC=""
if exist "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" set ISCC="%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
if exist "%ProgramFiles%\Inno Setup 6\ISCC.exe"      set ISCC="%ProgramFiles%\Inno Setup 6\ISCC.exe"
if exist "%ProgramFiles(x86)%\Inno Setup 5\ISCC.exe" set ISCC="%ProgramFiles(x86)%\Inno Setup 5\ISCC.exe"

if %ISCC%=="" (
    echo  [!] Inno Setup not found.
    echo.
    echo  Download free from: https://jrsoftware.org/isdl.php
    echo  Install it, then run this script again.
    echo.
    pause
    exit /b 1
)
echo  [OK] Inno Setup found.
echo.

:: ── Build installer ──────────────────────────────────────────────────────────
echo  Building flo_setup.exe...
echo.
mkdir installer 2>nul
%ISCC% flo_setup.iss

if errorlevel 1 (
    echo.
    echo  [ERROR] Installer build failed.
    pause
    exit /b 1
)

if exist "installer\flo_setup_v1.3.exe" (
    echo.
    echo  ========================================
    echo    INSTALLER READY
    echo    installer\flo_setup_v1.3.exe
    echo  ========================================
    echo.
    echo  Post this file as your GitHub release asset.
    echo  Users just double-click it — no Python needed.
    echo.
) else (
    echo  [ERROR] Installer not found after build.
)
pause
