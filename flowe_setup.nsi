; Flowe NSIS Installer
!define APP_NAME "Flowe"
!define APP_VERSION "1.7.0"
!define PUBLISHER "PrivacyChase"
!define APP_URL "https://privacychase.com"
!define INSTALL_DIR "$PROGRAMFILES64\Flowe"
!define UNINSTALL_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\Flowe"

Name "${APP_NAME} ${APP_VERSION}"
OutFile "installers\flowe_${APP_VERSION}_setup.exe"
InstallDir "${INSTALL_DIR}"
InstallDirRegKey HKLM "${UNINSTALL_KEY}" "InstallLocation"
RequestExecutionLevel admin
SetCompressor /SOLID lzma

; Modern UI
!include "MUI2.nsh"
!define MUI_ICON "assets\app_icon.ico"
!define MUI_UNICON "assets\app_icon.ico"
!define MUI_ABORTWARNING

; Welcome page
!define MUI_WELCOMEPAGE_TITLE "Flowe ${APP_VERSION}"
!define MUI_WELCOMEPAGE_TEXT "What's new in v1.7.0:$\r$\n$\r$\n- Transactions rebuilt: month nav, spending summary, grouped by date$\r$\n- Budget tab now includes Transactions as a sub-tab$\r$\n- Snowball, Net Worth, Events each get their own top-level tab$\r$\n- Split calculator total now saves correctly$\r$\n- Font size no longer resets when adding/deleting rows$\r$\n- Status bar and gesture bar overlap fixed on Android/iOS$\r$\n- Debt card field alignment fixed$\r$\n$\r$\nYour data is safe — installing over an existing version will not delete anything."

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN "$INSTDIR\flowe.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Launch Flowe"
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

Section "Install"
    SetOutPath "$INSTDIR"
    File /r "build\windows\x64\runner\Release\*.*"

    ; Start menu shortcut
    CreateDirectory "$SMPROGRAMS\Flowe"
    CreateShortcut "$SMPROGRAMS\Flowe\Flowe.lnk" "$INSTDIR\flowe.exe"
    CreateShortcut "$SMPROGRAMS\Flowe\Uninstall Flowe.lnk" "$INSTDIR\Uninstall.exe"

    ; Desktop shortcut
    CreateShortcut "$DESKTOP\Flowe.lnk" "$INSTDIR\flowe.exe"

    ; Write uninstaller
    WriteUninstaller "$INSTDIR\Uninstall.exe"

    ; Add/Remove Programs entry
    WriteRegStr HKLM "${UNINSTALL_KEY}" "DisplayName" "${APP_NAME}"
    WriteRegStr HKLM "${UNINSTALL_KEY}" "DisplayVersion" "${APP_VERSION}"
    WriteRegStr HKLM "${UNINSTALL_KEY}" "Publisher" "${PUBLISHER}"
    WriteRegStr HKLM "${UNINSTALL_KEY}" "URLInfoAbout" "${APP_URL}"
    WriteRegStr HKLM "${UNINSTALL_KEY}" "URLUpdateInfo" "${APP_URL}"
    WriteRegStr HKLM "${UNINSTALL_KEY}" "Comments" "Budget, snowball debt payoff, net worth, event split calculator, spending journal. v${APP_VERSION}: rebuilt Transactions, new tab layout, split calculator save fix, font size fix, safe area fixes."
    WriteRegStr HKLM "${UNINSTALL_KEY}" "DisplayIcon" "$INSTDIR\flowe.exe"
    WriteRegStr HKLM "${UNINSTALL_KEY}" "InstallLocation" "$INSTDIR"
    WriteRegStr HKLM "${UNINSTALL_KEY}" "UninstallString" "$INSTDIR\Uninstall.exe"
    WriteRegDWORD HKLM "${UNINSTALL_KEY}" "NoModify" 1
    WriteRegDWORD HKLM "${UNINSTALL_KEY}" "NoRepair" 1
SectionEnd

Section "Uninstall"
    Delete "$INSTDIR\Uninstall.exe"
    RMDir /r "$INSTDIR"
    Delete "$DESKTOP\Flowe.lnk"
    RMDir /r "$SMPROGRAMS\Flowe"
    DeleteRegKey HKLM "${UNINSTALL_KEY}"
SectionEnd
