; flo v1.4.2 NSIS Installer Script

!define APP_NAME        "flo"
!define APP_VERSION     "1.4.2"
!define APP_PUBLISHER   "speeddevilx"
!define APP_URL         "https://github.com/thatspeedykid/flo"
!define APP_EXE         "flo.exe"
!define INSTALL_DIR     "$LOCALAPPDATA\flo"
!define UNINSTALL_KEY   "Software\Microsoft\Windows\CurrentVersion\Uninstall\flo"

Name "${APP_NAME} ${APP_VERSION}"
OutFile "flo_setup.exe"
InstallDir "${INSTALL_DIR}"
InstallDirRegKey HKCU "${UNINSTALL_KEY}" "InstallLocation"
RequestExecutionLevel user
Unicode True
SetCompressor /SOLID lzma

; Installer icon (shows on the setup.exe itself)
Icon "assets\app_icon.ico"
UninstallIcon "assets\app_icon.ico"

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

  ; Replace the icon on the installed flo.exe using our .ico
  ; (the exe already has it embedded from build step — this is a safety copy)
  SetOutPath "$INSTDIR"

  ; Shortcuts
  CreateDirectory "$SMPROGRAMS\flo"
  CreateShortcut "$SMPROGRAMS\flo\flo.lnk"           "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0
  CreateShortcut "$SMPROGRAMS\flo\Uninstall flo.lnk" "$INSTDIR\uninstall.exe"
  CreateShortcut "$DESKTOP\flo.lnk"                  "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0

  ; Uninstaller
  WriteUninstaller "$INSTDIR\uninstall.exe"

  ; Add/Remove Programs
  WriteRegStr   HKCU "${UNINSTALL_KEY}" "DisplayName"      "${APP_NAME}"
  WriteRegStr   HKCU "${UNINSTALL_KEY}" "DisplayVersion"   "${APP_VERSION}"
  WriteRegStr   HKCU "${UNINSTALL_KEY}" "Publisher"        "${APP_PUBLISHER}"
  WriteRegStr   HKCU "${UNINSTALL_KEY}" "URLInfoAbout"     "${APP_URL}"
  WriteRegStr   HKCU "${UNINSTALL_KEY}" "InstallLocation"  "$INSTDIR"
  WriteRegStr   HKCU "${UNINSTALL_KEY}" "UninstallString"  "$INSTDIR\uninstall.exe"
  WriteRegStr   HKCU "${UNINSTALL_KEY}" "DisplayIcon"      "$INSTDIR\${APP_EXE}"
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoModify"         1
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoRepair"         1
SectionEnd

; ── Uninstall ──────────────────────────────────────────────────────────────────
Section "Uninstall"
  RMDir /r "$INSTDIR"
  Delete "$SMPROGRAMS\flo\flo.lnk"
  Delete "$SMPROGRAMS\flo\Uninstall flo.lnk"
  RMDir  "$SMPROGRAMS\flo"
  Delete "$DESKTOP\flo.lnk"
  DeleteRegKey HKCU "${UNINSTALL_KEY}"
  MessageBox MB_OK "flo has been uninstalled.$\n$\nYour data at %APPDATA%\flo\ was kept."
SectionEnd
