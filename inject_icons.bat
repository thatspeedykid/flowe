@echo off
:: Injects flo icons into Windows and Android platform runner folders
cd /d "%~dp0"
set ASSETS=%~dp0assets

echo [+] Injecting platform icons...

:: ── Windows ──────────────────────────────────────────────────────────────────
if exist "windows\runner\resources" (
    if exist "%ASSETS%\app_icon.ico" (
        copy /Y "%ASSETS%\app_icon.ico" "windows\runner\resources\app_icon.ico" >nul
        echo [OK] Windows icon injected.
    )
)

:: ── Android ──────────────────────────────────────────────────────────────────
if exist "android\app\src\main\res" (
    for %%f in (mipmap-mdpi mipmap-hdpi mipmap-xhdpi mipmap-xxhdpi mipmap-xxxhdpi) do (
        if exist "%ASSETS%\android_%%f.png" (
            if exist "android\app\src\main\res\%%f" (
                copy /Y "%ASSETS%\android_%%f.png" "android\app\src\main\res\%%f\ic_launcher.png" >nul
                echo [OK] Android %%f icon injected.
            )
        )
    )
)

echo [+] Icons done.
