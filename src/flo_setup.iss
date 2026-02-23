#define MyAppName "flo"
#define MyAppVersion "1.3"
#define MyAppPublisher "thatspeedykid"
#define MyAppURL "https://github.com/thatspeedykid/flo"
#define MyAppExeName "flo.exe"

[Setup]
AppId={{F7A2B3C4-1234-5678-ABCD-9E0F1A2B3C4D}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
; Install to user folder — no UAC needed, no shortcut permission errors
DefaultDirName={localappdata}\flo
DefaultGroupName=flo
AllowNoIcons=yes
OutputDir=installer
OutputBaseFilename=flo_setup_v{#MyAppVersion}
SetupIconFile=src\flo.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\flo.exe
UninstallDisplayName=flo — simple budget app
; Run as current user — avoids all UAC/permission issues
PrivilegesRequired=lowest
; Support upgrading older versions cleanly
CloseApplications=yes
CloseApplicationsFilter=flo.exe

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"

[Files]
Source: "src\dist\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; Start menu and desktop shortcuts — user-scoped, no permission issues
Name: "{userprograms}\flo\flo"; Filename: "{app}\{#MyAppExeName}"; Comment: "flo — simple budget app"
Name: "{userprograms}\flo\Uninstall flo"; Filename: "{uninstallexe}"
Name: "{userdesktop}\flo"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; Comment: "flo — simple budget app"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch flo now"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Leave user data untouched in %APPDATA%\flo — only remove the install folder
Type: filesandordirs; Name: "{app}"
