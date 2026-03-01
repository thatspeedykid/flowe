; flo v1.5.0 NSIS Installer Script

!define APP_NAME        "Flowe"
!define APP_VERSION     "1.5.0"
!define APP_PUBLISHER   "speeddevilx"
!define APP_URL         "https://github.com/thatspeedykid/flowe"
!define APP_EXE         "flowe.exe"
!define INSTALL_DIR     "$LOCALAPPDATA\Flowe"
!define UNINSTALL_KEY   "Software\Microsoft\Windows\CurrentVersion\Uninstall\Flowe"

Name "${APP_NAME} ${APP_VERSION}"
OutFile "installers\flowe_${APP_VERSION}_setup.exe"
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
  ; ── Migrate from old flo installation ──────────────────────────────────────
  ; If old flo is installed, run its uninstaller silently first
  ReadRegStr $0 HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\flo" "UninstallString"
  StrCmp $0 "" +3
    ExecWait '"$0" /S'
    Sleep 1000

  ; Copy old flo data to Flowe location if it exists
  StrCpy $0 "$APPDATA\flo\flo\data.json"
  IfFileExists $0 0 +4
    CreateDirectory "$APPDATA\flowe\flowe"
    CopyFiles /SILENT $0 "$APPDATA\flowe\flowe\data.json"
    DetailPrint "Migrated data from flo to Flowe"
  SetOutPath "$INSTDIR"

  ; Copy entire release bundle
  File /r "build\windows\x64\runner\Release\*.*"

  ; Replace the icon on the installed flowe.exe using our .ico
  ; (the exe already has it embedded from build step — this is a safety copy)
  SetOutPath "$INSTDIR"

  ; Shortcuts
  CreateDirectory "$SMPROGRAMS\Flowe"
  CreateShortcut "$SMPROGRAMS\Flowe\Flowe.lnk"           "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0
  CreateShortcut "$SMPROGRAMS\Flowe\Uninstall Flowe.lnk" "$INSTDIR\uninstall.exe"
  CreateShortcut "$DESKTOP\Flowe.lnk"                    "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0

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
  ; Delete only app files — never touch user data in %APPDATA%\flowe
  Delete "$INSTDIR\flowe.exe"
  Delete "$INSTDIR\flutter_windows.dll"
  Delete "$INSTDIR\uninstall.exe"
  RMDir /r "$INSTDIR\data"
  ; Only remove install dir if empty after cleanup
  RMDir "$INSTDIR"

  Delete "$SMPROGRAMS\Flowe\Flowe.lnk"
  Delete "$SMPROGRAMS\Flowe\Uninstall Flowe.lnk"
  RMDir  "$SMPROGRAMS\Flowe"
  Delete "$DESKTOP\Flowe.lnk"
  DeleteRegKey HKCU "${UNINSTALL_KEY}"
  MessageBox MB_OK "Flowe has been uninstalled.$\n$\nYour data at %APPDATA%\flowe\ was kept."
SectionEnd
