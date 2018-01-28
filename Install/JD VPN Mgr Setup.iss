#define MyAppName "JD VPN Manager"
#define MyAppVersion "1.0"
#define MyAppPublisher "JD Software Inc."
#define MyAppExeName "JDVPNMGR.exe"

[Setup]
AppId={{E0DF3A67-05AA-4644-AF9F-6AE505DB7878}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={pf}\JD Software\JD VPN Manager
DisableProgramGroupPage=yes
OutputDir=.\Output
OutputBaseFilename=JD_VPN_Mgr_Setup
SetupIconFile=..\Ras_Icon.ico
Compression=lzma
SolidCompression=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "..\Win32\Release\JDVPNMGR.exe"; DestDir: "{app}"; Flags: ignoreversion
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{commonprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Registry]
Root: HKCU; Subkey: "Software\JD Software\JD VPN Manager\Auto Reconnect"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\JD Software\JD VPN Manager"; Flags: uninsdeletekey     
Root: HKCU; Subkey: "Software\JD Software"; Flags: uninsdeletekeyifempty             

[Code]



