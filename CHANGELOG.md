# Changelog

All notable changes to the **Admin** PowerShell module are recorded here.
Fine-grained, line-level history lives in git (`git log`, `git blame`); this
file records the *why* in human terms, per the dated notes carried over from
the original module header.

## [2.0.0] - 2026-06-24

### Changed
- Restructured the module from a single 2,200-line `Admin.psm1` into a standard
  layout: a manifest (`Admin.psd1`), a thin loader (`Admin.psm1`), and one file
  per function under `Public\` and `Private\`. Function bodies are unchanged.
- `Export-Credential` and `New-FileNameWithTimestamp` are now private
  (non-exported) helpers used only by other functions in the module.
- Moved the 12 Citrix helpers out into a new, separate **CitrixTools** module.
  They depend on the `Citrix.*.Admin.V*` snap-ins, which are Windows PowerShell
  5.1 (Desktop) only; keeping them here forced a PS5 dependency on the whole
  module. Admin now exports 46 functions.

### Renamed (approved verbs; old names kept as aliases)
- `Transpose-Object` -> `ConvertTo-TransposedObject`
- `Clean-DesktopIcons` -> `Clear-DesktopIcons`

### Refactored
- `Get-VMInfoAllVMs_CSV` -> `Get-VMInfoAllVMs`. Now emits VM objects to the
  pipeline by default (was: always dumped CSVs to C:\temp). Added `-Platform`
  (VMware|Nutanix|Both, default Both) and `-ExportCsv` (writes one timestamped
  CSV per platform via `New-FileNameWithTimestamp` and returns the path(s)).
  No backward-compat alias: the default behavior changed deliberately.

### Modernized / best practices
- Swept the Admin functions (excluding the VM-projection family `Get-VMInfo`,
  `Find-VMByIPExact`, `Find-VMByIPLike`, which are being reworked separately):
  - Added comment-based help (.SYNOPSIS/.DESCRIPTION/.PARAMETER/.EXAMPLE/.OUTPUTS/
    .NOTES) to every function that lacked it; all functions now have help.
  - `[CmdletBinding()]` everywhere; `[OutputType()]` where the type is known.
  - `Get-SystemInfo` fully converted from `Get-WmiObject` to `Get-CimInstance`
    (no `Get-WmiObject` remains in the module). Note: CIM uses WS-Management, so
    targets need WinRM. Dropped the obsolete `ConvertToDateTime` calls (CIM returns
    real DateTime values) and wrapped the TCP port scan in try/catch.
  - Replaced cmdlet aliases (select/where/sort/%/ogv/ft/gc) with full cmdlet names.
  - `SupportsShouldProcess` added to state-changing commands (Enable-*,
    Restart-/Stop-ComputerAndPing, Clear-AutoRunCD, Remove-ProfilesFromRemoteComputer,
    Remove-Snapshot_OGV, Remove-VmAudioDevice_OGV); destructive ones default to
    ConfirmImpact High.
  - Fixed the "mandatory parameter with a default" pattern (dropped Mandatory where a
    local-machine default exists); added pipeline input on getters where natural.
- Fixes found while modernizing:
  - `Get-/Remove-ProfilesFromRemoteComputer` passed a string to `-CimSession` (which
    needs a session object); now create/dispose a real CIM session.
  - `Get-LoggedOnSessions_OGV` used the deprecated `quser | ConvertFrom-String`;
    now uses the same `-split` parsing as Clear-LoggedOnSessions.
  - `Enable-RemoteDesktop` and `Clear-AutoRunCD` leaked their PSSession; now use try/finally.
  - `Get-MyCredential` dropped its non-idiomatic `-Help` switch (use Get-Help).
- Documented the plaintext-password exposure in `Start-RDP` (.NOTES): the password
  is passed to cmdkey on the command line.

### Added
- Configuration system. Environment-specific values (PsExec path, privileged
  account, domain controller, AD search base, RD session prefix, default export
  path) are no longer hardcoded in function bodies; they come from config and are
  exposed through new overridable parameters on the affected functions
  (`Enable-RemoteDesktop/WinRM/WinRMSSL`, `Clear-DesktopIcons`,
  `Get-AllServersInComputersContainer`, `Get-/Invoke-RDUserLogoff_OGV`,
  `Get-VMInfoAllVMs`, `New-FileNameWithTimestamp`).
- Config is layered (later overrides earlier), so personal/per-machine choices
  survive `git pull`:
    1. `Admin.Config.psd1` in the repo  - org/baseline defaults (tracked, deploys)
    2. `%ProgramData%\Admin\Admin.Config.psd1` - per-machine override (untracked)
    3. `%APPDATA%\Admin\Admin.Config.psd1`     - per-user override, wins (untracked)
- `Get-AdminConfig` - view the merged effective settings (`-ListPaths` shows the
  layer files and which exist).
- `Set-AdminConfig -Name X -Value Y [-Scope User|Machine]` - persist an override
  to the user (default) or machine file; rebuilds the effective config in memory.
  Accepts arbitrary keys, so new defaults (e.g. a default vCenter list) can be
  stored without code changes. (Set-PowerCLIConfiguration-style.)

### Removed / merged
- Removed four commands no longer used in the current environment, along with the
  legacy former-employer config they depended on: `Clear-DesktopIcons`
  (+ `Clean-DesktopIcons` alias), `Get-AllServersInComputersContainer`,
  `Get-RDUserLogoff_OGV`, `Invoke-RDUserLogoff_OGV`. The associated config keys
  (`PrivilegedAccount`, `DomainController`, `ServersSearchBase`, `SessionUserPrefix`)
  are gone; `Admin.Config.psd1` now holds only generic, non-sensitive values
  (`PsExecPath`, `DefaultExportPath`). Note: these values still exist in earlier
  git history (commit 8d2bd4b) -- removing them from history would require a
  history rewrite. Admin now exports 43 functions.
- Removed `Clear-LoggedOnSessions_OGV` (deprecated `quser | ConvertFrom-String`
  parsing). Its interactive-select behavior is now `Clear-LoggedOnSessions -Select`.
  No alias kept on purpose: aliasing the old name would silently turn a
  "pick sessions" call into "log off everyone."

### Changed
- `Clear-LoggedOnSessions`: now logs off ALL sessions by default; added `-Select`
  to choose specific sessions via Out-GridView (the previous behavior). Renamed
  `-RemoteComputerName` to `-ComputerName` (alias `RemoteComputerName` kept), and
  added `SupportsShouldProcess` so `-WhatIf`/`-Confirm` work. Known limitation
  carried over: quser parsing misaligns columns for disconnected sessions.

### Fixed
- `Clear-LoggedOnSessions_OGV` (before removal): typo `$colmun4` -> `$column4`.
- `Get-MyCredential`: `Break` -> `return` so the no-args/`-Help` path exits only
  the function, not an enclosing loop in the caller. Also escaped `$CredPath` in
  the help text so it prints literally instead of interpolating an empty value.

## History (pre-2.0, from the original module header)

- 2026.04.09 - Add Get-WhoIs
- 2025.10.09 - Add Transpose-Object
- 2025.10.02 - Fix Find-ADUser
- 2025.09.04 - Add Find-FilesContainingText
- 2025.07.17 - New-FileNameWithTimestamp and cleanup
- 2025.04.28 - Add Get-SSLCertificateExpirationDate
- 2025.04.16 - Add Get-RemoteDiskUsage
- 2025.04.01 - Add Nutanix support to VM commands (VM info)
- 2025.03.31 - Begin rewrite for Nutanix compatibility
- 2024.11.15 - Add Clear-LoggedOnSessions (cleaner command, AI-assisted)
- 2024.09.25 - Update all VMInfo functions
- 2024.06.05 - Add last snapshot to VMInfo
- 2024.03.08 - Add Get-RebootHistory
- 2024.03.04 - Update Find-VMInfo to new Get-VMInfo query
- 2024.03.01 - Add cluster info to Get-VMInfo
- 2023.07.21 - Add Get-LoggedOnUser
- 2023.02 - Add find VM by IP (exact)
- 2023.01.20 - Add find VM by IP
- 2022.12.29 - Update Get-VMInfo with cluster and vCenter info; remove cluster group from info
- 2022.09.20 - Add Get-VMHost to Get-VMInfo functions
- 2022.07.11 - Add Get-VMInfo and Get-VMInfo_OGV
- 2022.06.07 - Add New-IsoFile
- 2022.05.16 - Get-IndependentDrives: limit to powered-on, Independent Persistent disks; add vCenter column
- 2021.12.29 - Add Test-Credential
- 2021.08.17 - Update
- 2021.03.22 - Update
- 2020.08.12 - Initial module (Greg Pennings)
