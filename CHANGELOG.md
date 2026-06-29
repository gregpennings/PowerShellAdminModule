# Changelog

All notable changes to the **Admin** PowerShell module are recorded here.
Fine-grained, line-level history lives in git (`git log`, `git blame`); this
file records the *why* in human terms, per the dated notes carried over from
the original module header.

## [3.0.0] - 2026-06-26

Added Microsoft Hyper-V as a third VM platform alongside VMware and Nutanix.
Major bump because the platform selector's default behavior changed (see Changed).

### Added
- Hyper-V support across the VM-info family. `Get-VMInfo` and `Get-VMInfoAllVMs`
  now query Hyper-V hosts and normalize them into the same object shape as VMware
  and Nutanix; `Find-VMByIPExact`/`Find-VMByIPLike` inherit it (they wrap
  `Get-VMInfo`). Select Hyper-V alone with `-Platform HyperV`.
- Hyper-V session management. Unlike VMware (`Connect-VIServer`) and Nutanix
  (`Connect-PrismCentral`), Hyper-V has no ambient connection -- each cmdlet
  reaches a host explicitly. So the module now holds CIM sessions, keyed by host,
  in a module-scoped store, with three new exported functions:
  - `Connect-HyperVHost` -- opens/refreshes CIM sessions and "mounts" them for the
    session (call it from your profile, beside Connect-VIServer/-PrismCentral).
    Hosts default to the configured `HyperVHosts` list; current identity by
    default, `-Credential` for workgroup/other-domain hosts.
  - `Get-HyperVSession` -- read-only view of the mounted sessions.
  - `Disconnect-HyperVHost` -- closes sessions (all, or named hosts).
  Standalone and clustered hosts are both supported: list every cluster node and
  clustered VMs are deduped by VM id, so they are never double-counted.
  Module now exports 31 functions (was 27).
- `Get-HyperVHostFromAD` -- discovers Hyper-V hosts from Active Directory by
  finding the "Microsoft Hyper-V" service connection point each host publishes
  under its computer object, and returns their DNS host names. Catches standalone
  hosts and every failover-cluster node (filtering by OS would miss role-enabled
  Windows Servers). `-Server` targets a different domain/forest (e.g. `hci.pvt`).
- `Connect-HyperVHost -FromAD` -- mounts every host `Get-HyperVHostFromAD` finds,
  so the host list needs no manual upkeep (new hosts appear automatically). This
  is the recommended way to wire it into a profile: `Connect-HyperVHost -FromAD`.
- `HyperVHosts` config key (baseline empty) -- the host list `Connect-HyperVHost`
  uses when called with no `-ComputerName` and without `-FromAD`. Set it
  per-machine/user with
  `Set-AdminConfig -Name HyperVHosts -Value @('hv01','hv02','clusternodeA')`.

### Added (general, unrelated to Hyper-V)
- `Update-PowerShell` -- updates PowerShell 7 to the latest release with guard
  rails: checks the latest version and skips if already current (`-Force` to
  override), prefers `winget` when available and falls back to the official
  `https://aka.ms/install-powershell.ps1 -UseMSI` bootstrap (`-UseMSI` forces it),
  requires elevation for the MSI path, and supports `-WhatIf`/`-Confirm`,
  `-Preview`, and `-Quiet`. Module now exports 32 functions.

### Changed
- **Breaking:** the module now requires **PowerShell 7.0+** (`PowerShellVersion`
  raised from `5.1`; `CompatiblePSEditions = Core`). Several functions use
  PowerShell 7 syntax, so it no longer loads under Windows PowerShell 5.1. (Citrix
  helpers already live in the separate CitrixTools module, which keeps the 5.1
  snap-in dependency out of here.)
- **Breaking:** the `-Platform` default on `Get-VMInfo` and `Get-VMInfoAllVMs` is
  now `All` (was `Both`). With three platforms "Both" no longer fits, so the
  canonical values are `All | VMware | Nutanix | HyperV`. `Both` is still accepted
  as a silent synonym for `All`, so existing calls and scripts keep working --
  but the default now also sweeps Hyper-V. If you relied on "Both" meaning
  "VMware + Nutanix only," pass `-Platform VMware,Nutanix`... (note: the selector
  is single-value; to exclude Hyper-V, query the platforms you want explicitly).

### Notes
- Hyper-V data is sparser than VMware by nature: guest OS, DNS name, and tags are
  not on the Hyper-V VM object. IP addresses are gathered from the VM's network
  adapters (and used to satisfy `-IPExact`/`-IPLike`); rows without a DnsName fall
  through to the existing reverse-DNS step. Checkpoint age and disk sizing are
  best-effort (extra remote calls; null on failure).
- The Hyper-V (`Hyper-V`) module is a soft dependency -- it is not added to the
  manifest's RequiredModules so the Admin module still imports on machines without
  the Hyper-V feature. The Hyper-V code paths only run when you mount a host.

## [2.0.4] - 2026-06-26

Documentation and a small quality-of-life addition. Mined the PowerShell session
transcripts again -- this time for real invocation patterns -- and folded the
useful ones back into the functions' help (deidentified, since this repo is public).

### Added
- `Select-StringFromObject` (alias `grep`) -- greps the *formatted display text*
  of piped objects, packaging the recurring `... | Out-String -Stream |
  Select-String <text>` idiom into one step. Collects all input and formats once
  so table headers/alignment survive; passes through `-CaseSensitive`,
  `-SimpleMatch`, `-NotMatch`, `-Context`, and `-Width` (widen to avoid column
  truncation). Matches display text, not property values -- use `Where-Object`
  for the latter. Module now exports 27 functions (was 26).

### Documentation
- Added real-usage `.EXAMPLE`s (generalized to placeholders) to `Find-VMByIPLike`
  and `Find-VMByIPExact` (had none), and to `Get-ADUserGroupMembership` (positional
  form + the `| grep <group>` entitlement check), `Get-VMInfo`, `Get-Whois`
  (documents the `whois` alias), and `Start-RDP` (load a credential once, reuse
  across hosts).
- Reformatted `New-IsoFile`'s comment-based help, which was collapsed onto a single
  line and therefore unparseable by `Get-Help`; its examples now display.

## [2.0.3] - 2026-06-26

Usage-driven cleanup. Reviewed ~5,400 commands across the PowerShell session
transcripts to identify functions never invoked, then trimmed dead weight and
consolidated one redundant variant. Module now exports 26 functions (was 43).

### Removed (zero usage in transcripts, no internal/profile dependents)
- `Clear-AutoRunCD`, `Find-FilesContainingText`, `Get-IndependentDrives`,
  `Get-LoggedOnUser`, `Get-MotionHistory`, `Get-RebootHistory`,
  `Get-RemoteDiskUsage`, `Test-URI`.
- The unused `_OGV` interactive variants `Get-ADGroupMember_OGV`,
  `Remove-Snapshot_OGV`, `Remove-VmAudioDevice_OGV`.
- The `Find-InstalledApplication` family (`Find-InstalledApplication`,
  `Find-InstalledApplicationOnAllServers`, `Find-InstalledApplicationOnAllWorkstations`).
- `Get-CertificateCryptographicProvider_OGV` (light use) removed by request.
- `Get-VIEventPlus` removed by request.
- All removed functions remain recoverable from git history.

### Consolidated
- `Get-ADUserGroupMembership_OGV` folded into `Get-ADUserGroupMembership` as a
  `-GridView` switch (shows enabled users in a grid, returns the selected user's
  groups). The standalone `_OGV` function is removed.

### Renamed / refactored
- `Get-LoggedOnSessions_OGV` -> `Get-LoggedOnSessions`. Now emits session objects
  to the pipeline instead of forcing `Out-GridView`; pipe to `Out-GridView` (`ogv`)
  yourself when you want the grid. No back-compat alias -- the old name is removed.

### Kept despite low/zero transcript usage
- Break-glass / rare-by-design tools retained intentionally: `Enable-RemoteDesktop`,
  `Enable-WinRMSSL`, `New-IsoFile`, `Get-SystemInfo`,
  `Get-ProfilesFromRemoteComputer`, `Remove-ProfilesFromRemoteComputer`,
  `Stop-ComputerAndPing`.
- `Get-VMInfoAllVMs` kept — it is a distinct full-inventory/CSV-export tool, not a
  variant of `Get-VMInfo`.
- `Set-AdminConfig`/`Get-AdminConfig` (config infrastructure) and
  `Test-Credential`/`Get-MyCredential` (invoked by the user profile at startup).

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
