@echo off
setlocal enabledelayedexpansion
title flo v1.4.0 - Windows Build

echo ╔══════════════════════════════════════╗
echo ║  flo v1.4.0 - Windows Build          ║
echo ╚══════════════════════════════════════╝
echo.

:: ── Check Flutter ─────────────────────────────────────────────────────────────
where flutter >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Flutter not found in PATH.
    echo Download: https://docs.flutter.dev/get-started/install/windows
    pause & exit /b 1
)

:: ── Get dependencies ───────────────────────────────────────────────────────────
echo ^> Getting Flutter dependencies...
flutter pub get
if errorlevel 1 ( echo [ERROR] flutter pub get failed & pause & exit /b 1 )

:: ── Build release ─────────────────────────────────────────────────────────────
echo ^> Building Windows release...
flutter build windows --release
if errorlevel 1 ( echo [ERROR] Flutter build failed & pause & exit /b 1 )
echo [OK] Flutter build done

:: ── Create installer with NSIS ────────────────────────────────────────────────
where makensis >nul 2>&1
if errorlevel 1 (
    echo.
    echo [INFO] NSIS not found - skipping installer creation.
    echo        Install NSIS from https://nsis.sourceforge.io to build an installer.
    echo.
    echo [OK] Release files are at:
    echo      build\windows\x64\runner\Release\
    echo.
    echo Copy that folder anywhere and run flo.exe
    pause & exit /b 0
)

echo ^> Building NSIS installer...
makensis flo_setup.nsi
if errorlevel 1 ( echo [ERROR] NSIS build failed & pause & exit /b 1 )

echo.
echo ╔══════════════════════════════════════╗
echo ║  [OK] flo_setup.exe built!           ║
echo ║  Distribute flo_setup.exe            ║
echo ╚══════════════════════════════════════╝
pause
