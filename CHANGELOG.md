# Changelog — TIA Portal V17 port

> This is a port of **[hadefuwa/tia-portal-mcp](https://github.com/hadefuwa/tia-portal-mcp)**
> (MIT licence, `master` @ 27 commits) retargeted from **TIA Portal V20** to
> **TIA Portal V17**. All credit for the original design, dashboard, MCP server,
> LAD builder and documentation belongs to the upstream author; changes below
> are only what this fork modified or added.

## 1.0.1
- **WebView2 `E_ACCESSDENIED` fix** (`MainForm.cs`): the embedded browser now
  stores its user data under `%LOCALAPPDATA%\TiaPortalMcpV17\WebView2` instead
  of the default folder next to the exe — the old location crashes when the
  app is installed in `C:\Program Files`. If the embedded view still fails, a
  plain message is shown and the dashboard opens in the default browser
  (the HTTP server already serves `dashboard.html` at `/`) instead of a JIT
  crash dialog.
- Installer uninstalls the WebView2 runtime-data folder (created on first run).
- Installer file is now versioned: `TiaPortalMCP-V17-Setup-1.0.1.exe`.

## 1.0.0
- **Inno Setup installer** (`installer/`): installs to Program Files, Desktop /
  Start Menu shortcuts, prerequisite checks (TIA V17 / .NET 4.8 / WebView2)
  that warn instead of blocking, auto-adds the logged-on user to the
  `Siemens TIA Openness` group, clean uninstall.
  Ships `Add-OpennessUser.ps1` + `them-vao-nhom-openness.cmd` (re-runnable
  group helper, always exits 0), `HUONG-DAN-CAI-DAT.txt` (Vietnamese guide),
  `opencode-config.jsonc` (OpenCode snippet).
- **TIA V17 pre-check** (`Program.cs`): friendly message when TIA V17 is not
  found — MessageBox in dashboard mode, stderr warning in `--mcp-stdio` mode,
  clean error from `connect_to_tia_portal` instead of `FileNotFoundException`.

## V17 port (from upstream V20)
- `.csproj` references `Portal V17\PublicAPI\V17\Siemens.Engineering(.Hmi).dll`;
  `TiaVersion=V17`; `.ap20` → `.ap17`; V20 strings/paths → V17.
- **HMI (WinCC Unified) gated** behind `#if HMI_UNIFIED` + `TiaHmi=false`
  (plain STEP 7 / WinCC Advanced V17 has no `HmiUnified` API): 7 HMI tools
  excluded from build — profiles are full=32, standard=27, lite=10,
  readonly=15. Re-enable with `-p:TiaHmi=true`, no code changes.
- **SimaticML v5 → v4** (`SW/Interface/v4`, `SW/FlgNet/v4`,
  `Engineering version="V17"`) per the official V17 XSDs; 22 golden samples
  in `docs/lad-samples/` converted; 45 unit tests pass.
- **`<Namespace>` element removed** from generated block XML (FB/LAD,
  GlobalDB, InstanceDB): live-tested — TIA V17 rejects it as "not supported".
- Docs updated (`README.md`, `docs/user-manual.md`); `.gitignore` covers
  `*.ap17`, `dist/`, `installer/staging/`.

## Live verification (TIA Portal V17 + S7-1200 1212C)
Connect, list devices/blocks/tags, SCL FB create, LAD seal-in FB import +
compile (0 errors), GlobalDB + InstanceDB import, tag table import + readback,
Main OB compile, save, MCP stdio handshake (32 tools, no HMI leakage).
