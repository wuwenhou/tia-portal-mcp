; ── TIA Portal MCP V17 — Inno Setup installer ─────────────────────────────────
; Builds TiaPortalMCP-V17-Setup.exe from a published build in .\staging\
;
; Steps to build:
;   1. dotnet publish src\TiaOpennessMcpServer\TiaOpennessMcpServer.csproj -c Release -o installer\staging
;   2. Delete installer\staging\*.pdb and installer\staging\TiaPortalDashboard.exe.WebView2\
;   3. ISCC.exe installer\Setup.iss   ->  dist\TiaPortalMCP-V17-Setup.exe
#define MyAppName "TIA Portal MCP V17"
#define MyAppVersion "1.0.1"
#define MyAppExe "TiaPortalDashboard.exe"

[Setup]
AppId={{155EC5BF-CE17-465A-8A02-07E1C6F663BF}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher=wuwenhou (fork of hadefuwa/tia-portal-mcp, ported to TIA V17)
AppPublisherURL=https://github.com/wuwenhou/tia-portal-mcp
DefaultDirName={autopf}\TIA Portal MCP V17
DefaultGroupName=TIA Portal MCP V17
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
Compression=lzma2
SolidCompression=yes
OutputDir={#SourcePath}\..\dist
OutputBaseFilename=TiaPortalMCP-V17-Setup
WizardStyle=modern
UninstallDisplayName={#MyAppName}
; The Siemens TIA Openness group only exists after TIA Portal is installed,
; so the installer warns instead of blocking when TIA V17 is missing.

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "opennessgroup"; Description: "Add the logged-on user to the 'Siemens TIA Openness' group (required for the app to talk to TIA Portal)"; GroupDescription: "TIA Portal:"; Flags: checkedonce

[Files]
; Main app (staging is produced by dotnet publish, then cleaned of *.pdb and
; the TiaPortalDashboard.exe.WebView2\ runtime-data folder — see header above).
Source: "staging\*"; DestDir: "{app}"; Excludes: "*.pdb,TiaPortalDashboard.exe.WebView2"; Flags: ignoreversion recursesubdirs createallsubdirs
; Helper script also runs from {tmp} during install (dontcopy copy).
Source: "Add-OpennessUser.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Add-OpennessUser.ps1"; Flags: dontcopy
Source: "them-vao-nhom-openness.cmd"; DestDir: "{app}"; Flags: ignoreversion
Source: "HUONG-DAN-CAI-DAT.txt"; DestDir: "{app}"; Flags: ignoreversion isreadme
Source: "opencode-config.jsonc"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\TIA Portal Dashboard"; Filename: "{app}\{#MyAppExe}"
Name: "{group}\Huong dan cai dat"; Filename: "{app}\HUONG-DAN-CAI-DAT.txt"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\TIA Portal Dashboard"; Filename: "{app}\{#MyAppExe}"; Tasks: desktopicon

; WebView2 runtime-data folder is created on first run (never installed) —
; remove it on uninstall so no leftovers remain.
[UninstallDelete]
Type: filesandordirs; Name: "{app}\TiaPortalDashboard.exe.WebView2"

[Run]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{tmp}\Add-OpennessUser.ps1"""; Tasks: opennessgroup; Flags: runhidden waituntilterminated; StatusMsg: "Adding user to Siemens TIA Openness group..."

[Code]
const
  TiaEngDll = 'C:\Program Files\Siemens\Automation\Portal V17\PublicAPI\V17\Siemens.Engineering.dll';
  WV2Key = 'SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}';

function IsTiaV17Installed(): Boolean;
begin
  Result := FileExists(TiaEngDll);
end;

function IsDotNet48Installed(): Boolean;
var
  Release: Cardinal;
begin
  Result := RegQueryDWordValue(HKLM, 'SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full', 'Release', Release)
    and (Release >= 528040);
end;

function IsWebView2Installed(): Boolean;
begin
  Result := RegKeyExists(HKLM, WV2Key) or RegKeyExists(HKLM32, WV2Key);
end;

// Console (physically logged-on) user — NOT the elevated admin account the
// installer itself runs as. Returns '' when it cannot be determined.
function GetConsoleUser(): String;
var
  Locator, Service, Items, Item: Variant;
  U: String;
  P, I, Count: Integer;
begin
  Result := '';
  try
    Locator := CreateOleObject('WbemScripting.SWbemLocator');
    Service := Locator.ConnectServer('.', 'root\CIMV2');
    Items := Service.ExecQuery('SELECT UserName FROM Win32_ComputerSystem');
    Count := Items.Count;
    for I := 0 to Count - 1 do
    begin
      Item := Items.ItemIndex(I);
      U := Item.UserName;
    end;
    P := Pos('\', U);
    if P > 0 then Delete(U, 1, P);
    Result := U;
  except
    Result := '';
  end;
end;

function InitializeSetup(): Boolean;
var
  Warn: String;
begin
  Result := True;
  Warn := '';
  if not IsTiaV17Installed() then
    Warn := Warn + '- TIA Portal V17 (with Openness API) was NOT found.' + #13#10 +
      '  The app will install, but it CANNOT run until TIA Portal V17 is installed.' + #13#10#13#10;
  if not IsDotNet48Installed() then
    Warn := Warn + '- .NET Framework 4.8 was NOT found (Windows 10 1903+ / Windows 11 include it).' + #13#10#13#10;
  if not IsWebView2Installed() then
    Warn := Warn + '- WebView2 Runtime was NOT found.' + #13#10 +
      '  Download it from: https://developer.microsoft.com/microsoft-edge/webview2/' + #13#10#13#10;
  if Warn <> '' then
    SuppressibleMsgBox('Missing prerequisites:' + #13#10#13#10 + Warn +
      'Continue installing anyway?', mbInformation, MB_YESNO, IDYES);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
    ExtractTemporaryFile('Add-OpennessUser.ps1');
end;

function UpdateReadyMemo(Space, NewLine, MemoUserInfoInfo, MemoDirInfo, MemoTypeInfo,
  MemoComponentsInfo, MemoGroupInfo, MemoTasksInfo: String): String;
begin
  Result := '';
  if MemoTasksInfo <> '' then
    Result := Result + 'Tasks:' + NewLine + MemoTasksInfo + NewLine + NewLine;
  if not IsTiaV17Installed() then
    Result := Result + 'NOTE: TIA Portal V17 was not detected — install it before running the app.' + NewLine;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = wpFinished then
    WizardForm.FinishedLabel.Caption :=
      'Setup has finished installing TIA Portal MCP V17.' + #13#10 + #13#10 +
      'NEXT STEPS:' + #13#10 +
      '1. If the user was just added to the "Siemens TIA Openness" group, SIGN OUT and SIGN IN again (required).' + #13#10 +
      '2. Open TIA Portal V17 with a .ap17 project, then click Connect in the dashboard.' + #13#10 +
      '3. At the first TIA access prompt, click "Yes to all".' + #13#10 + #13#10 +
      'See HUONG-DAN-CAI-DAT.txt in the install folder for details (Vietnamese).';
end;
