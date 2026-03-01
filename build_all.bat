@echo off
setlocal
cd /d "%~dp0"
set VERSION=1.4.2
title flo v%VERSION% - Build All
echo.
echo ==========================================
echo   flo v%VERSION% - Build All Platforms
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
if exist "build\windows\x64\runner\Release\flo.exe" (
    echo [OK] Windows EXE built.
) else ( echo [ERROR] EXE not found & goto :fail )
echo.

:: ── Step 4: Android APK ───────────────────────────────────────────────────────
echo [4/5] Building Android APK...
call flutter build apk --release
if errorlevel 1 goto :fail
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    copy /Y "build\app\outputs\flutter-apk\app-release.apk" "installers\flo_%VERSION%.apk" >nul
    echo [OK] Android APK: installers\flo_%VERSION%.apk
) else ( echo [ERROR] APK not found & goto :fail )
echo.

:: ── Step 5: NSIS Installer ────────────────────────────────────────────────────
echo [5/5] Building Windows installer...
where makensis >nul 2>&1
if errorlevel 1 (
    echo [INFO] NSIS not found - skipping. Get it: https://nsis.sourceforge.io
    goto :done
)
if not exist "flo_setup.nsi" ( echo [INFO] flo_setup.nsi missing & goto :done )
makensis flo_setup.nsi
if errorlevel 1 goto :fail
if exist "flo_setup.exe" (
    move /Y "flo_setup.exe" "installers\flo_%VERSION%_setup.exe" >nul
    echo [OK] Installer: installers\flo_%VERSION%_setup.exe
)
echo.

:done
echo ==========================================
echo   BUILD COMPLETE  -^>  installers\
echo ==========================================
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
