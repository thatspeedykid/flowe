@echo off
echo ==========================================
echo   WSL2 + Flutter Setup (run once)
echo ==========================================
echo.

:: Auto-elevate to admin if not already
net session >nul 2>&1
if errorlevel 1 (
    echo [INFO] Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process cmd -ArgumentList '/c cd /d \"%~dp0\" && \"%~f0\"' -Verb RunAs"
    exit /b
)

:: Check if WSL is already working
wsl -- echo "WSL_OK" >nul 2>&1
if not errorlevel 1 (
    echo [OK] WSL is already working. Skipping Windows feature install.
    goto :install_flutter
)

echo [1/3] Enabling WSL and Virtual Machine Platform...
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
echo.

echo [2/3] Installing WSL2 kernel update...
:: Download and install WSL2 kernel update
powershell -Command "Invoke-WebRequest -Uri 'https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi' -OutFile '%TEMP%\wsl_update.msi' -UseBasicParsing"
msiexec /i "%TEMP%\wsl_update.msi" /quiet /norestart
wsl --set-default-version 2

echo [3/3] Installing Ubuntu...
wsl --install -d Ubuntu
echo.
echo ==========================================
echo   RESTART REQUIRED
echo ==========================================
echo.
echo Windows features have been enabled.
echo Please RESTART your PC, then run this
echo script again to install Flutter in WSL.
echo.
pause
exit /b 0

:install_flutter
echo [INFO] Checking for Ubuntu distro...
:: wsl -l outputs UTF-16 so we use wsl -e to test directly instead
wsl -d Ubuntu -- echo "UBUNTU_OK" >nul 2>&1
if errorlevel 1 (
    :: Try launching it - it may just need first-time setup
    echo [INFO] Ubuntu found but needs first-time setup.
    echo Please open a new terminal, run:  wsl -d Ubuntu
    echo Set your username and password, then run this script again.
    pause & exit /b 0
)

echo [INFO] Installing Flutter in WSL...
wsl -- bash -lc "sudo apt-get update -qq 2>/dev/null && sudo apt-get install -y -qq curl git unzip xz-utils clang cmake ninja-build pkg-config libgtk-3-dev libblkid-dev liblzma-dev lld binutils 2>/dev/null && sudo snap remove flutter 2>/dev/null || true && if [ ! -f \"$HOME/flutter/bin/flutter\" ]; then cd ~ && git clone https://github.com/flutter/flutter.git -b stable --depth 1 2>/dev/null && echo 'export PATH=\"$PATH:$HOME/flutter/bin\"' >> ~/.bashrc && echo 'export PATH=\"$PATH:$HOME/flutter/bin\"' >> ~/.profile; fi && export PATH=\"$HOME/flutter/bin:$PATH\" && flutter precache --linux 2>/dev/null && flutter --version"

echo.
echo ==========================================
echo   WSL Flutter setup complete!
echo ==========================================
echo You can now run build_all.bat to build
echo Windows + Android + Linux all at once.
echo.
pause
