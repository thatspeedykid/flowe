@echo off
setlocal enabledelayedexpansion
title flo v1.4.1 - Build All Platforms
chcp 65001 >nul

echo ==========================================
echo   flo v1.4.1 - Build All Platforms
echo   Windows EXE + Linux DEB + Android APK
echo ==========================================
echo.

:: ── Check Flutter ─────────────────────────────────────────────────────────────
where flutter >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Flutter not found in PATH.
    echo Download: https://docs.flutter.dev/get-started/install/windows
    pause & exit /b 1
)

:: ── Step 1: Dependencies ──────────────────────────────────────────────────────
echo [1/4] Getting Flutter dependencies...
flutter pub get
if errorlevel 1 ( echo [ERROR] flutter pub get failed & pause & exit /b 1 )
echo.

:: ── Step 2: Ensure platform folders exist ────────────────────────────────────
echo [2/4] Ensuring platform support is configured...
flutter create --platforms=windows,linux,android . >nul 2>&1
echo Done.
echo.

:: ── Step 3: Build Windows ─────────────────────────────────────────────────────
echo [3/4] Building Windows release...
flutter build windows --release
if errorlevel 1 ( echo [ERROR] Windows build failed & pause & exit /b 1 )
echo [OK] Windows build done.
echo      Output: build\windows\x64\runner\Release\
echo.

:: ── Step 4: Build Android APK ─────────────────────────────────────────────────
echo [4/4] Building Android APK...
flutter build apk --release
if errorlevel 1 (
    echo [WARN] Android build failed. Is Android SDK installed?
    echo        Install Android Studio: https://developer.android.com/studio
    echo        Then run: flutter doctor
    echo.
    goto :windows_installer
)
echo [OK] Android APK done.
echo      Output: build\app\outputs\flutter-apk\app-release.apk
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    copy "build\app\outputs\flutter-apk\app-release.apk" "flo_1.4.1.apk" >nul
    echo      Copied to: flo_1.4.1.apk
)
echo.

:windows_installer
:: ── Step 5: Build installer (NSIS optional) ───────────────────────────────────
where makensis >nul 2>&1
if errorlevel 1 (
    echo [INFO] NSIS not installed - portable build only.
    echo        To build flo_setup.exe: https://nsis.sourceforge.io
    echo        Then re-run this script.
    echo.
    goto :done
)

echo [+] Building Windows installer...
makensis flo_setup.nsi
if errorlevel 1 ( echo [ERROR] NSIS failed & goto :done )
echo [OK] Installer built: flo_setup.exe
echo.

:done
echo ==========================================
echo   Build Summary
echo ==========================================
if exist "build\windows\x64\runner\Release\flo.exe" (
    echo [OK] Windows:  build\windows\x64\runner\Release\flo.exe
) else (
    echo [--] Windows:  not built
)
if exist "flo_1.4.1.apk" (
    echo [OK] Android:  flo_1.4.1.apk
) else (
    echo [--] Android:  not built (requires Android SDK)
)
if exist "flo_setup.exe" (
    echo [OK] Installer: flo_setup.exe
) else (
    echo [--] Installer: not built (requires NSIS)
)
echo.
echo Note: Linux DEB must be built on Linux - run: bash build_all.sh
echo ==========================================
pause
