# Building Flowe from Source

This guide covers everything needed to build Flowe on every supported platform — from a completely fresh machine with nothing installed.

**Outputs:**
- `installers/flowe_1.7.0_setup.exe` — Windows installer
- `installers/flowe_1.7.0_amd64.deb` — Linux package
- `installers/flowe_1.7.0.apk` — Android APK
- `installers/flowe_1.7.0.dmg` — macOS disk image *(requires Mac or CI)*
- `installers/flowe_1.7.0.ipa` — iOS archive *(requires Mac or CI)*

> **Tip:** You don't need Apple hardware to build iOS/macOS. See [GitHub Actions CI](#github-actions-ci--no-hardware-needed) below.

---

## Table of Contents

- [GitHub Actions CI — no hardware needed](#github-actions-ci--no-hardware-needed)
- [Windows — builds EXE + APK](#windows--builds-exe--apk)
- [Linux — builds DEB](#linux--builds-deb)
- [macOS — builds DMG + IPA](#macos--builds-dmg--ipa)
- [Troubleshooting](#troubleshooting)

---

## GitHub Actions CI — no hardware needed

The repo includes a workflow at `.github/workflows/build.yml` that builds all 5 platforms in the cloud — including iOS and macOS — using GitHub's free runners. No Apple hardware required.

### Running a build

1. Go to your GitHub repo → **Actions** tab
2. Click **Build & Sign All Platforms** in the left sidebar
3. Click **Run workflow** → enter version number → **Run workflow**
4. Wait ~15–20 minutes
5. Download all artifacts from the workflow run summary page

### Adding signing credentials

Unsigned builds work fine for direct distribution. To produce store-signed builds, add secrets at **Settings → Secrets and variables → Actions**.

See **[SIGNING.md](SIGNING.md)** for the full step-by-step guide covering Android keystore generation, Apple certificate export, and Windows code signing.

---

## Windows — builds EXE + APK

Builds the Windows `.exe` installer and Android `.apk` in one run.

### 1. Install Git

Download and install from https://git-scm.com/download/win

Accept all defaults. Verify:
```bat
git --version
```

---

### 2. Install Flutter

1. Download the Flutter SDK zip from https://docs.flutter.dev/get-started/install/windows
2. Extract to `C:\flutter` (the folder should contain `bin\flutter.bat`)
3. Add to PATH:
   - Open **Start** → search **"Environment Variables"**
   - Under **User variables**, select **Path** → **Edit** → **New**
   - Add `C:\flutter\bin`
   - Click OK on all dialogs
4. Open a **new** Command Prompt and verify:
```bat
flutter --version
flutter doctor
```

---

### 3. Install Android Studio + SDK

1. Download from https://developer.android.com/studio
2. Run the installer, accept all defaults
3. On first launch, go through the **Setup Wizard** — let it download the Android SDK
4. Open **SDK Manager** (Tools menu):
   - **SDK Platforms**: check **Android 14 (API 34)** or newer
   - **SDK Tools**: check **Android SDK Build-Tools**, **Android SDK Command-line Tools**, **Android Emulator**, **Android SDK Platform-Tools**
   - Click **Apply**
5. Set environment variables:
   - `ANDROID_HOME` = `C:\Users\<YourName>\AppData\Local\Android\Sdk`
   - Add to **Path**: `%ANDROID_HOME%\platform-tools`
6. Accept licenses in a new Command Prompt:
```bat
flutter doctor --android-licenses
```
Type `y` for each prompt.

---

### 4. Install Java 17

1. Download JDK 17 from https://adoptium.net (click **Latest LTS Release**)
2. Run the installer — check **Set JAVA_HOME variable** during install
3. Verify in a new Command Prompt:
```bat
java -version
```

If `JAVA_HOME` wasn't set automatically, add it manually:
- `JAVA_HOME` = `C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot`

---

### 5. Install Visual Studio (C++ workload)

1. Download **Visual Studio Community** from https://visualstudio.microsoft.com/vs/community/
2. In the installer, select **"Desktop development with C++"**
3. Click Install

Required for the Windows `.exe` build. You never need to open Visual Studio.

---

### 6. Install NSIS

1. Download from https://nsis.sourceforge.io/Download
2. Run the installer, accept all defaults
3. Installs to `C:\Program Files (x86)\NSIS\` — found automatically by the build script

---

### 7. Clone and build

Open **Command Prompt** (not PowerShell):

```bat
git clone https://github.com/thatspeedykid/flowe.git
cd flowe
build_all.bat
```

All outputs land in `installers\`.

---

### Optional: Linux .deb from Windows via WSL

1. Open **PowerShell as Administrator**:
```powershell
wsl --install -d Ubuntu
```
2. Reboot, then open **Ubuntu** from Start menu and set a username/password
3. Run the one-time WSL Flutter setup from the flowe directory:
```bat
setup_wsl_flutter.bat
```
4. `build_all.bat` will now build the `.deb` automatically as step 5

---

## Linux — builds DEB

Tested on Ubuntu 24.04. Other Debian-based distros should work.

### 1. Install dependencies

```bash
sudo apt-get update
sudo apt-get install -y git curl unzip xz-utils clang cmake ninja-build \
    pkg-config libgtk-3-dev libblkid-dev liblzma-dev lld binutils
```

---

### 2. Install Flutter (manual — do NOT use snap)

> ⚠️ **Never install Flutter via `snap install flutter`** — the snap bundles an incomplete LLVM-10 that is missing `ld.lld` and cannot be patched (snap directories are read-only). Always use the manual install below.

If you already have the snap, remove it first:
```bash
sudo snap remove flutter
```

Then install manually:
```bash
git clone https://github.com/flutter/flutter.git -b stable --depth 1 ~/flutter
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
flutter precache --linux
flutter --version
```

---

### 3. Clone and build

```bash
git clone https://github.com/thatspeedykid/flowe.git
cd flowe
flutter build linux --release
bash build_deb_wsl.sh
```

The `.deb` lands at `installers/flowe_1.7.0_amd64.deb`.

Install it:
```bash
sudo dpkg -i installers/flowe_1.7.0_amd64.deb
```

---

## macOS — builds DMG + IPA

> ⚠️ Requires a Mac with Xcode, **or** use the [GitHub Actions CI](#github-actions-ci--no-hardware-needed) workflow instead.

### 1. Install Xcode

Install from the **App Store**, then:
```bash
xcode-select --install
sudo xcodebuild -license accept
```

### 2. Install Homebrew + tools

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install create-dmg
sudo gem install cocoapods
```

### 3. Install Flutter

```bash
git clone https://github.com/flutter/flutter.git -b stable --depth 1 ~/flutter
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zshrc
source ~/.zshrc
flutter precache --macos --ios
flutter doctor
```

### 4. Clone and build

```bash
git clone https://github.com/thatspeedykid/flowe.git
cd flowe
bash build_all_mac.sh
```

Outputs land in `~/Documents/flowe-builds/`.

---

## Troubleshooting

### `flutter doctor` shows issues
Run `flutter doctor -v` for verbose output. Most issues are missing PATH entries or unaccepted Android licenses.

### Windows: `JAVA_HOME` not found
Open a **new** Command Prompt after setting the variable. Verify: `echo %JAVA_HOME%`

### Windows: Kotlin incremental cache error during Android build
Happens when your Pub cache (`C:\Users\...`) and project (`D:\...`) are on different drives. Already handled in `build_all.bat`. If it persists:
```bat
flutter clean
build_all.bat
```

### Windows: NSIS installer not produced
Make sure NSIS is installed at `C:\Program Files (x86)\NSIS\`. Check the build log for the NSIS step output.

### Linux: `CMake is required`
```bash
sudo apt-get install -y cmake
```

### Linux: `Could not find compiler set in environment variable CXX: clang++`
```bash
sudo apt-get install -y clang
```

### Linux: `Failed to find any of [ld.lld, ld]`
You have snap Flutter installed. Remove it:
```bash
sudo snap remove flutter
git clone https://github.com/flutter/flutter.git -b stable --depth 1 ~/flutter
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
flutter precache --linux
```

### Linux: dpkg conflict with old `flo` package
```bash
sudo dpkg --remove flo
sudo dpkg -i installers/flowe_1.7.0_amd64.deb
```

### macOS: CocoaPods issues
```bash
sudo gem install cocoapods
pod setup
```

### macOS: Xcode license not accepted
```bash
sudo xcodebuild -license accept
```

### All platforms: clean build
```bash
flutter clean
flutter pub get
```

---

*Built by [PrivacyChase](https://privacychase.com) — software that respects you.*
