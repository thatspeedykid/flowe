; flo v1.4.0 NSIS Installer Script
; Requires NSIS 3.x — https://nsis.sourceforge.io

!define APP_NAME        "flo"
!define APP_VERSION     "1.4.1"
!define APP_PUBLISHER   "speeddevilx"
!define APP_URL         "https://github.com/thatspeedykid/flo"
!define APP_EXE         "flo.exe"
!define INSTALL_DIR     "$LOCALAPPDATA\flo"
!define UNINSTALL_KEY   "Software\Microsoft\Windows\CurrentVersion\Uninstall\flo"

Name "${APP_NAME} ${APP_VERSION}"
OutFile "flo_setup.exe"
InstallDir "${INSTALL_DIR}"
InstallDirRegKey HKCU "${UNINSTALL_KEY}" "InstallLocation"
RequestExecutionLevel user   ; No UAC prompt
Unicode True
SetCompressor /SOLID lzma

; ── Pages ──────────────────────────────────────────────────────────────────────
Page directory
Page instfiles
UninstPage uninstConfirm
UninstPage instfiles

; ── Install ────────────────────────────────────────────────────────────────────
Section "Install"
  SetOutPath "$INSTDIR"

  ; Copy entire release bundle
  File /r "build\windows\x64\runner\Release\*.*"

  ; Start menu shortcut
  CreateDirectory "$SMPROGRAMS\flo"
  CreateShortcut "$SMPROGRAMS\flo\flo.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}"
  CreateShortcut "$SMPROGRAMS\flo\Uninstall flo.lnk" "$INSTDIR\uninstall.exe"

  ; Desktop shortcut
  CreateShortcut "$DESKTOP\flo.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}"

  ; Write uninstaller
  WriteUninstaller "$INSTDIR\uninstall.exe"

  ; Add/Remove Programs entry
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayName"      "${APP_NAME}"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayVersion"   "${APP_VERSION}"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "Publisher"        "${APP_PUBLISHER}"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "URLInfoAbout"     "${APP_URL}"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "InstallLocation"  "$INSTDIR"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "UninstallString"  "$INSTDIR\uninstall.exe"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayIcon"      "$INSTDIR\${APP_EXE}"
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoModify"       1
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoRepair"       1

  MessageBox MB_OK "flo ${APP_VERSION} installed!$\n$\nLaunch from your Start Menu or Desktop shortcut."
SectionEnd

; ── Uninstall ──────────────────────────────────────────────────────────────────
Section "Uninstall"
  ; Remove files (keep data — user's financial data stays safe)
  RMDir /r "$INSTDIR"

  ; Remove shortcuts
  Delete "$SMPROGRAMS\flo\flo.lnk"
  Delete "$SMPROGRAMS\flo\Uninstall flo.lnk"
  RMDir  "$SMPROGRAMS\flo"
  Delete "$DESKTOP\flo.lnk"

  ; Remove registry
  DeleteRegKey HKCU "${UNINSTALL_KEY}"

  MessageBox MB_OK "flo has been uninstalled.$\n$\nYour data at %APPDATA%\flo\flo\ was kept."
SectionEnd
