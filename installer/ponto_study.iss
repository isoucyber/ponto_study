; ============================================================
; ARQUIVO: installer/ponto_study.iss
; FUNÇÃO: Script do Inno Setup que gera o instalador do Windows
;         (PontoStudy-Setup-<versão>.exe), com atalhos no menu Iniciar
;         e na área de trabalho, e desinstalador.
;
; Executado pelo GitHub Actions depois de "flutter build windows":
;   iscc /DMyAppVersion=0.1.0 installer\ponto_study.iss
;
; POSSO ALTERAR: nome do editor (MyAppPublisher), textos e ícones.
; NÃO DEVO ALTERAR: AppId. Ele identifica o app para atualizações;
;   mudar o AppId faz o Windows tratar como outro programa.
; ============================================================

#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif

#define MyAppName "Ponto Study"
#define MyAppPublisher "Ponto Study"
#define MyAppExeName "ponto_study.exe"

[Setup]
AppId={{8C2F6E1A-5B4D-4E7A-9F3C-2D1B0A9E8F71}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\Ponto Study
DefaultGroupName=Ponto Study
DisableProgramGroupPage=yes
OutputDir=..\dist\Windows
OutputBaseFilename=PontoStudy-Setup-{#MyAppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequiredOverridesAllowed=dialog
CloseApplications=yes

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Desinstalar {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent
