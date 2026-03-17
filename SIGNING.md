# Setting Up Code Signing

This guide covers how to generate/export each signing credential and add it to GitHub so the CI workflow can produce signed, store-ready builds.

All secrets live at: **GitHub repo → Settings → Secrets and variables → Actions → New repository secret**

---

## Android — Google Play

### Step 1: Generate a keystore (run once, keep the file safe forever)

On any machine with Java installed:

```bash
keytool -genkey -v \
  -keystore flowe.jks \
  -alias flowe \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

You'll be prompted for:
- A **store password** (save this)
- Your name/org details (can be anything)
- A **key password** (save this — can be same as store password)

> ⚠️ Back up `flowe.jks` somewhere safe. If you lose it you can never update your app on Google Play.

### Step 2: Encode and add secrets

```bash
# On Linux/macOS:
base64 -w 0 flowe.jks > flowe.jks.b64

# On Windows (PowerShell):
[Convert]::ToBase64String([IO.File]::ReadAllBytes("flowe.jks")) | Out-File flowe.jks.b64
```

Add these 4 secrets to GitHub:

| Secret name | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Contents of `flowe.jks.b64` |
| `ANDROID_KEY_ALIAS` | `flowe` (or whatever alias you used) |
| `ANDROID_KEY_PASSWORD` | The key password you chose |
| `ANDROID_STORE_PASSWORD` | The store password you chose |

### Step 3: Wire up `android/app/build.gradle`

Add this block to `android/app/build.gradle` inside `android { ... }`:

```groovy
def keyPropertiesFile = rootProject.file("key.properties")
def keyProperties = new Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(new FileInputStream(keyPropertiesFile))
}

signingConfigs {
    release {
        keyAlias keyProperties['keyAlias']
        keyPassword keyProperties['keyPassword']
        storeFile keyProperties['storeFile'] ? file(keyProperties['storeFile']) : null
        storePassword keyProperties['storePassword']
    }
}

buildTypes {
    release {
        signingConfig signingConfigs.release
    }
}
```

The CI workflow writes `android/key.properties` automatically from your secrets at build time.

---

## iOS — App Store

### Step 1: Enroll in Apple Developer Program

Go to https://developer.apple.com/programs/enroll/ — costs $99/year.

### Step 2: Create an App ID

1. Go to https://developer.apple.com → Certificates, IDs & Profiles → Identifiers
2. Click **+** → App IDs → App
3. Bundle ID: `com.privacychase.flowe`
4. Enable any capabilities you need (none required for Flowe)
5. Click Register

### Step 3: Create a Distribution Certificate

1. Go to Certificates → **+**
2. Select **Apple Distribution**
3. Follow the CSR instructions (you'll need a Mac or use a tool like [Certificate Signing Request generator](https://developers.google.com/android/management/generate-csr))
4. Download the `.cer` file
5. Double-click to import into Keychain Access
6. In Keychain, find it under **My Certificates**, right-click → **Export**
7. Save as `.p12`, set a password

```bash
# Encode it:
base64 -i distribution.p12 | pbcopy
```

Add secrets:

| Secret name | Value |
|---|---|
| `IOS_DISTRIBUTION_CERT_BASE64` | Paste from clipboard |
| `IOS_DISTRIBUTION_CERT_PASSWORD` | The .p12 password you set |

### Step 4: Create a Provisioning Profile

1. Go to Profiles → **+**
2. Select **App Store Connect** (under Distribution)
3. Select your App ID (`com.privacychase.flowe`)
4. Select your Distribution Certificate
5. Name it `flowe_appstore`
6. Download the `.mobileprovision` file

```bash
base64 -i flowe_appstore.mobileprovision | pbcopy
```

Add secret:

| Secret name | Value |
|---|---|
| `IOS_PROVISIONING_PROFILE_BASE64` | Paste from clipboard |

### Step 5: Add your Team ID

Find your Team ID at https://developer.apple.com/account → Membership Details.

| Secret name | Value |
|---|---|
| `APPLE_TEAM_ID` | Your 10-character Team ID (e.g. `ABC123DEF4`) |

---

## macOS — Mac App Store

Same process as iOS but with macOS-specific certificate and profile types.

### Step 1: Create a macOS Distribution Certificate

1. Certificates → **+** → **Apple Distribution** (same cert works for both iOS and macOS)
   - Or create a separate **Mac App Distribution** cert if you prefer
2. Export as `.p12` same as above

```bash
base64 -i macos_distribution.p12 | pbcopy
```

| Secret name | Value |
|---|---|
| `MACOS_DISTRIBUTION_CERT_BASE64` | Paste from clipboard |
| `MACOS_DISTRIBUTION_CERT_PASSWORD` | The .p12 password |

### Step 2: Create a macOS Provisioning Profile

1. Profiles → **+** → **Mac App Store** (under Distribution)
2. Select App ID `com.privacychase.flowe`
3. Download the `.provisionprofile`

```bash
base64 -i flowe_mac.provisionprofile | pbcopy
```

| Secret name | Value |
|---|---|
| `MACOS_PROVISIONING_PROFILE_BASE64` | Paste from clipboard |

---

## Windows — Code Signing (optional)

Windows signing removes the SmartScreen "Windows protected your PC" warning. It's optional — unsigned builds work fine for direct distribution.

### Option A: Self-signed (free, but SmartScreen still warns)
Not worth doing — SmartScreen requires an EV certificate with reputation history anyway.

### Option B: Standard OV certificate (~$70-200/year)
From providers like Sectigo, DigiCert, or Certum. Removes the warning after your app builds enough reputation.

### Option C: EV certificate (~$300-400/year)
Instant SmartScreen trust, no reputation building needed.

When you have a `.pfx` certificate:

```bash
base64 -w 0 certificate.pfx > certificate.b64
```

| Secret name | Value |
|---|---|
| `WINDOWS_CERT_BASE64` | Contents of `certificate.b64` |
| `WINDOWS_CERT_PASSWORD` | Certificate password |

Then uncomment the signing step in `.github/workflows/build.yml`.

---

## Running the workflow

Once secrets are added:

1. Go to your GitHub repo → **Actions** tab
2. Click **Build & Sign All Platforms**
3. Click **Run workflow** → enter version → **Run workflow**
4. Wait ~15-20 minutes
5. Download all 5 signed artifacts from the workflow run summary

---

## Secret checklist

| Secret | Platform | Required for store? |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | Android | ✅ Yes |
| `ANDROID_KEY_ALIAS` | Android | ✅ Yes |
| `ANDROID_KEY_PASSWORD` | Android | ✅ Yes |
| `ANDROID_STORE_PASSWORD` | Android | ✅ Yes |
| `IOS_DISTRIBUTION_CERT_BASE64` | iOS | ✅ Yes |
| `IOS_DISTRIBUTION_CERT_PASSWORD` | iOS | ✅ Yes |
| `IOS_PROVISIONING_PROFILE_BASE64` | iOS | ✅ Yes |
| `MACOS_DISTRIBUTION_CERT_BASE64` | macOS | ✅ Yes |
| `MACOS_DISTRIBUTION_CERT_PASSWORD` | macOS | ✅ Yes |
| `MACOS_PROVISIONING_PROFILE_BASE64` | macOS | ✅ Yes |
| `APPLE_TEAM_ID` | iOS + macOS | ✅ Yes |
| `WINDOWS_CERT_BASE64` | Windows | ❌ Optional |
| `WINDOWS_CERT_PASSWORD` | Windows | ❌ Optional |
