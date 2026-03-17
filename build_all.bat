@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
set VERSION=1.7.0
title Flowe v%VERSION% - Build All
echo.
echo ==========================================
echo   Flowe v%VERSION% - Build All Platforms
echo   Windows Installer + Android APK + Linux
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
echo   [OK] Dependencies ready.
echo.

:: ── Step 2: Platform setup + icon injection ───────────────────────────────────
echo [2/5] Setting up platforms and injecting icons...

:: Delete main.cpp so flutter create regenerates it clean (prevents C++ corruption)
if exist "windows\runner\main.cpp" del "windows\runner\main.cpp" >nul 2>&1

call flutter create --platforms=windows,android . >nul 2>&1

:: Patch Android package ID (covers both groovy and kotlin gradle)
powershell -NoProfile -Command "foreach ($f in @('android\app\build.gradle','android\app\build.gradle.kts')) { if (Test-Path $f) { (gc $f) -replace 'com\.example\.flowe','com.privacychase.flowe' | sc $f } }" >nul 2>&1
powershell -NoProfile -Command "(gc 'android\app\src\main\AndroidManifest.xml') -replace 'com\.example\.flowe','com.privacychase.flowe' | sc 'android\app\src\main\AndroidManifest.xml'" >nul 2>&1
echo   [OK] Android package ID patched to com.privacychase.flowe

:: Patch Runner.rc — app name, version info, publisher
if exist "windows\runner\Runner.rc" (
    python patch_rc.py
)

call inject_icons.bat
echo.

:: ── Step 3: Windows build ─────────────────────────────────────────────────────
echo [3/5] Building Windows release...
call flutter build windows --release
if errorlevel 1 goto :fail

set RELEASE_DIR=build\windows\x64\runner\Release
if not exist "%RELEASE_DIR%\flowe.exe" (
    echo [ERROR] flowe.exe not found in %RELEASE_DIR%
    goto :fail
)
echo   [OK] Windows EXE built.

:: Build installer with NSIS if available, otherwise fall back to ZIP
set MAKENSIS=
where makensis >nul 2>&1
if not errorlevel 1 (
    set "MAKENSIS=makensis"
) else if exist "C:\Program Files (x86)\NSIS\Bin\makensis.exe" (
    set "MAKENSIS=C:\Program Files (x86)\NSIS\Bin\makensis.exe"
) else if exist "C:\Program Files (x86)\NSIS\makensis.exe" (
    set "MAKENSIS=C:\Program Files (x86)\NSIS\makensis.exe"
) else if exist "C:\Program Files\NSIS\Bin\makensis.exe" (
    set "MAKENSIS=C:\Program Files\NSIS\Bin\makensis.exe"
) else (
    set "MAKENSIS="
)

if not "!MAKENSIS!"=="" (
    echo   Building installer with NSIS...
    "!MAKENSIS!" flowe_setup.nsi
    if exist "installers\flowe_%VERSION%_setup.exe" (
        echo   [OK] Windows Installer: installers\flowe_%VERSION%_setup.exe
    ) else (
        echo   [WARN] NSIS ran but installer not found - check flowe_setup.nsi
    )
) else (
    echo   [INFO] NSIS not found - building ZIP instead.
    echo   Get NSIS from https://nsis.sourceforge.io for a proper installer.
    set WIN_ZIP=installers\flowe_%VERSION%_windows.zip
    if exist "!WIN_ZIP!" del "!WIN_ZIP!"
    powershell -NoProfile -Command "Compress-Archive -Path '%RELEASE_DIR%\*' -DestinationPath 'installers\flowe_%VERSION%_windows.zip'"
    if exist "installers\flowe_%VERSION%_windows.zip" (
        echo   [OK] Windows ZIP: installers\flowe_%VERSION%_windows.zip
    )
)
echo.

:: ── Step 4: Android APK ───────────────────────────────────────────────────────
echo [4/5] Building Android APK...
:: Wipe ALL plugin Kotlin incremental caches under build\
:: These break when Pub cache (C:\Users\...) and project (D:\...) are on
:: different drives - Kotlin cannot relativize cross-drive paths.
:: kotlin.incremental=false in gradle.properties prevents new ones forming,
:: but stale caches from previous builds must be cleared manually.
for /d %%D in ("build\*") do (
    if exist "%%D\kotlin" rd /s /q "%%D\kotlin" >nul 2>&1
)
call flutter build apk --release
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    copy /Y "build\app\outputs\flutter-apk\app-release.apk" "installers\flowe_%VERSION%.apk" >nul
    echo   [OK] Android APK: installers\flowe_%VERSION%.apk
) else (
    echo   [WARN] Android APK not produced - check Android SDK / JAVA_HOME
)
echo.

:: ── Step 5: Linux .deb via WSL ────────────────────────────────────────────────
echo [5/5] Building Linux .deb via WSL...
where wsl >nul 2>&1
if errorlevel 1 (
    echo   [SKIP] WSL not found.
    goto :done
)
wsl -d Ubuntu -- echo "WSL_OK" >nul 2>&1
if errorlevel 1 (
    echo   [SKIP] Ubuntu WSL not set up. Run setup_wsl_flutter.bat first.
    goto :done
)
wsl -d Ubuntu -- bash -c "test -f ~/flutter/bin/flutter" >nul 2>&1
if errorlevel 1 (
    echo   [SKIP] Flutter not in WSL. Run setup_wsl_flutter.bat first.
    goto :done
)

:: Convert path to WSL format - write a small launcher to avoid space issues
set WIN_PATH=%~dp0
set WIN_PATH=%WIN_PATH:~0,-1%
for /f "tokens=1,2 delims=:" %%a in ("%WIN_PATH%") do (set DRV=%%a & set REST=%%b)
for /f %%i in ('powershell -NoProfile -Command "'%DRV%'.ToLower()"') do set DRV_LOWER=%%i
set REST_UNIX=%REST:\=/%
set WSL_PATH=/mnt/%DRV_LOWER%%REST_UNIX%

:: Copy the build script into WSL tmp and run it with the project path
wsl -d Ubuntu -- cp "%WSL_PATH%/wsl_build_linux.sh" /tmp/wsl_build_linux.sh
wsl -d Ubuntu -- chmod +x /tmp/wsl_build_linux.sh
echo   Building Linux release (this takes a few minutes)...
wsl -d Ubuntu -- bash /tmp/wsl_build_linux.sh "%WSL_PATH%"

set DEB=installers\flowe_%VERSION%_linux_amd64.deb
if exist "%DEB%" (
    echo   [OK] Linux .deb: %DEB%
) else (
    echo   [WARN] Linux .deb not found - check output above for errors
)
echo.

:done
echo ==========================================
echo   BUILD COMPLETE  -^>  installers\
echo ==========================================
echo.
echo   Built on this machine:
dir "installers\" /b 2>nul
echo.
echo   macOS + iOS (requires a Mac):
echo   Copy project to Mac, then run: bash build_all_mac.sh
echo   Produces: flowe_%VERSION%.dmg + flowe_%VERSION%.ipa
echo   Output goes to: ~/Documents/flowe-builds/
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
