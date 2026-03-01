@echo off
setlocal
cd /d "%~dp0"
set VERSION=1.5.0
title Flowe v%VERSION% - Build All
echo.
echo ==========================================
echo   Flowe v%VERSION% - Build All Platforms
echo   Windows EXE + Android APK
echo ==========================================
echo.

if not exist "installers" mkdir installers

where flutter >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Flutter not found in PATH.
    pause & exit /b 1
)

:: ── Step 1: Dependencies ──────────────────────────────────────────────────────
echo [1/5] Getting dependencies...
call flutter pub get
if errorlevel 1 goto :fail
echo [OK] Dependencies ready.
echo.

:: ── Step 2: Platform setup + icon injection ───────────────────────────────────
echo [2/5] Setting up platforms and injecting icons...
call flutter create --platforms=windows,android . >nul 2>&1
call inject_icons.bat
echo.

:: ── Step 3: Windows EXE ───────────────────────────────────────────────────────
echo [3/5] Building Windows release...
call flutter build windows --release
if errorlevel 1 goto :fail

:: Flutter uses app name from pubspec — find whatever .exe was built
set EXE_PATH=build\windows\x64\runner\Release
set EXE_FOUND=0
if exist "%EXE_PATH%\flowe.exe" set EXE_FOUND=1
if exist "%EXE_PATH%\flo.exe"   set EXE_FOUND=1
if "%EXE_FOUND%"=="0" (
    echo [ERROR] EXE not found. Contents of %EXE_PATH%:
    dir "%EXE_PATH%\*.exe" 2>nul
    goto :fail
)
echo [OK] Windows EXE built.
echo.

:: ── Step 4: Android APK (optional — skipped if Android SDK not configured) ────
echo [4/5] Building Android APK...
call flutter build apk --release 2>nul
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    if not exist "installers" mkdir installers
    copy /Y "build\app\outputs\flutter-apk\app-release.apk" "installers\flowe_%VERSION%.apk" >nul
    echo [OK] Android APK: installers\flowe_%VERSION%.apk
) else (
    echo [INFO] Android APK skipped (Android SDK not configured or build failed)
)
echo.

:: ── Step 5: NSIS Installer ────────────────────────────────────────────────────
echo [5/5] Building Windows installer...
where makensis >nul 2>&1
if errorlevel 1 (
    echo [INFO] NSIS not found - skipping. Get it: https://nsis.sourceforge.io
    goto :done
)
if not exist "flowe_setup.nsi" (
    echo [INFO] flowe_setup.nsi not found - skipping.
    goto :done
)
if not exist "installers" mkdir installers
makensis flowe_setup.nsi
if errorlevel 1 goto :fail
if exist "installers\flowe_%VERSION%_setup.exe" (
    echo [OK] Installer: installers\flowe_%VERSION%_setup.exe
) else (
    echo [WARN] Installer may have been built with different version in .nsi
)
echo.

:done
echo ==========================================
echo   BUILD COMPLETE  ->  installers\
echo ==========================================
echo.
echo Contents of installers\:
dir "installers\" 2>nul
echo.
pause
exit /b 0

:fail
echo.
echo ==========================================
echo   BUILD FAILED - see errors above
echo ==========================================
echo.
pause
exit /b 1
