# PowerShell Admin Module

`Admin` is a PowerShell module of administrative utilities for remote systems,
Active Directory, VMware/Nutanix/Hyper-V infrastructure, credential handling, and
general system administration.

> Citrix helpers were moved out into the separate **CitrixTools** module (they
> require the `Citrix.*.Admin.V*` snap-ins, which are Windows PowerShell 5.1 only).

## Installation

1. Place the `Admin` module folder in a PowerShell module path.
   - Example (per-user, no elevation required to write/update): `C:\Users\<username>\Documents\PowerShell\Modules\Admin`
2. Import the module in your PowerShell session:
   ```powershell
   Import-Module Admin
   ```
3. Optionally add `Import-Module Admin` to your PowerShell profile.
   - Example profile path: `C:\Users\<username>\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`

## Requirements

- PowerShell 7.0 or higher (PowerShell Core; the module no longer targets Windows
  PowerShell 5.1 -- several functions use PowerShell 7 syntax). On a machine that
  only has Windows PowerShell 5.1, bootstrap 7 first with the bundled standalone
  script (it is 5.1-compatible and does not need the module):
  `powershell.exe -ExecutionPolicy Bypass -File .\Install-PowerShell7.ps1`
- `ActiveDirectory` module for AD-related commands
- VMware PowerCLI modules for VMware commands (`VMware.VimAutomation.Core` and related cmdlets)
- Nutanix Prism PowerShell module for Nutanix VM commands (`Nutanix.Prism.PS.Cmds`)
- `Hyper-V` module for Hyper-V VM commands (Windows feature; soft dependency -- the
  module imports without it, but the Hyper-V code paths require it)
- Internet access for `Get-Whois` and SSL certificate checks

## New Workstation / New Account Checklist

Everything below is per-Windows-account: a fresh machine has none of it, and
neither does a second account on a machine that's already set up for your
main one -- e.g. a tiered admin account such as `ADM<name>` used for AD/infra
work. Run this checklist logged in as (or elevated as) whichever account will
actually run the module.

1. **PowerShell 7+.** Check with `$PSVersionTable.PSVersion`. If it's below
   7.0 (or `pwsh` doesn't exist), bootstrap it with the bundled 5.1-compatible
   script: `powershell.exe -ExecutionPolicy Bypass -File .\Install-PowerShell7.ps1`
2. **Git**, to clone/pull the repo. Check with `git --version`.
   - If `winget` itself isn't recognized, bootstrap it first -- this happens
     on an account that's never touched the Microsoft Store (Store apps are
     registered per-profile, not per-machine, so a fresh account -- e.g. a
     tiered admin account -- can lack it even though it's provisioned on the
     box). No elevation needed for this part:
     ```powershell
     Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
     Install-Module Microsoft.WinGet.Client -Scope CurrentUser -Force -AllowClobber
     Repair-WinGetPackageManager -Latest -Force
     winget --version   # confirm it now returns a version
     ```
     `Install-PackageProvider -Name NuGet` commonly fails first with "No
     match was found ... requires 'PackageManagement' and 'Provider' tags"
     on PowerShell 7 -- that's a known, benign PS7/`PackageManagement`
     quirk, not a real blocker. Skip it and continue; `Install-Module` and
     `Repair-WinGetPackageManager` still succeed without it.
   - Then install Git itself. This step *does* need elevation (Run as
     Administrator), since it writes to `Program Files`:
     ```powershell
     winget install --id Git.Git --source winget --scope machine --accept-package-agreements --accept-source-agreements
     ```
     Open a fresh terminal afterward -- PATH only updates in new sessions.
3. **Clone the module into that account's own per-user module path** --
   specifically the *first* entry of `$env:PSModulePath`, normally
   `C:\Users\<account>\Documents\PowerShell\Modules\Admin`. Check the actual
   first entry with `($env:PSModulePath -split ';')[0]` rather than assuming,
   since it can vary.
   ```powershell
   git clone <repo-url> (Join-Path ($env:PSModulePath -split ';')[0] 'Admin')
   ```
   This has to be a normal per-account git clone, not a shared/machine-wide
   copy: the profile script (step 4) keeps it current by running `git pull`
   against exactly this path on every launch. It also must NOT live inside
   the versioned `...\PowerShell\7\Modules` folder -- that's tied to the PS7
   install itself and isn't a stable place for a git working tree (this is
   why it was moved out to a normal per-account module path).
4. **Deploy the PowerShell profile.** The `Admin` module import, its
   auto-update (`git pull`), and the startup connections to vCenter/Prism/
   Hyper-V all live in the separate, private **`PowerShellCustomProfile`**
   repo, not in this one -- see that repo's own README for what it does and
   why it's private. Clone it, then point `$PROFILE` at its
   `Microsoft.PowerShell_profile.ps1` (find your path with `$PROFILE`; each
   account/host combination has its own):
   ```powershell
   # Symlink (elevated), or dot-source from a tiny $PROFILE -- see that repo's README
   New-Item -ItemType SymbolicLink -Path $PROFILE -Target '<path-to>\PowerShellCustomProfile\Microsoft.PowerShell_profile.ps1'
   ```
   If you're not using that profile on this account, at minimum add
   `Import-Module Admin` to `$PROFILE` yourself so the module loads on
   startup.
5. **Install the dependency modules** under that account, or once with
   `-Scope AllUsers` (elevated) to cover every account on the box at once --
   unlike the `Admin` module itself, these are ordinary gallery modules with
   no auto-update tie to a specific path:
   - `ActiveDirectory`: an RSAT feature on client Windows, not a gallery
     module -- `Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0`.
     First run can sit at "Running" for 15-20+ minutes fetching the payload
     from Windows Update -- that's normal, not a hang. If it's still
     `NotPresent` after a long wait, retry via `DISM /Online /Add-Capability
     /CapabilityName:Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0` instead --
     it reports real percent progress, so you can tell slow from stuck. Zero
     movement there points to a blocked network path to Windows Update, not
     a PowerShell problem.
   - VMware PowerCLI: `Install-Module VMware.PowerCLI -Scope AllUsers -Force`.
     Also run `Set-PowerCLIConfiguration -Scope AllUsers -ParticipateInCeip
     $false -Confirm:$false` once -- otherwise the first `Connect-VIServer`
     triggers an interactive CEIP prompt, which will hang the profile script
     (step 4) the first time it runs unattended.
   - Nutanix: `Install-Module Nutanix.Cli -Scope AllUsers -Force -AllowClobber`.
     `-AllowClobber` is required, not optional here: this package installs
     `Nutanix.Prism.PS.Cmds`, which defines cmdlets with the same names as
     VMware PowerCLI (`Get-VM`, `New-VM`, `Start-VM`, etc.) -- expected, and
     exactly why this module's own `Get-VMInfo` exists to normalize across
     platforms instead of relying on the raw cmdlet names.
   - `Hyper-V`: a Windows feature, not a gallery module. Every workstation
     running this profile needs it -- but only the PowerShell management
     tools sub-feature, not the full role, since `Connect-HyperVHost` reaches
     hosts remotely via CIM sessions rather than running VMs locally:
     `Enable-WindowsOptionalFeature -Online -FeatureName
     Microsoft-Hyper-V-Management-PowerShell -All -NoRestart`. Only use the
     full role (`Microsoft-Hyper-V-All`, requires a reboot) if that
     workstation will actually host VMs itself.
   - OpenSSH Client: often already present by default on Windows 10
     (1809+)/11 -- check first with `Get-WindowsCapability -Online -Name
     OpenSSH.Client*`. If `NotPresent`:
     `Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0`.
   - OpenSSL at `C:\Program Files\OpenSSL` -- not required by this module,
     but the profile script (step 4) adds it to `PATH`/`OPENSSL_CONF` on
     every launch and will warn if it's missing.
   These are soft dependencies: `Import-Module Admin` succeeds without them,
   and only the commands for a given platform fail until it's installed.
6. **Redo configuration and credentials -- none of this carries over between
   accounts, even on the same machine:**
   - `Set-AdminConfig` at the default `-Scope User` writes to `%APPDATA%\Admin`
     (per-profile). Either rerun it under the new account, or use
     `-Scope Machine` (`%ProgramData%\Admin`, shared by every account on the
     box) for settings everyone should share, e.g.
     `Set-AdminConfig -Name HyperVHosts -Value @('hv01','hv02') -Scope Machine`.
   - Anything saved via `Get-MyCredential` or `Start-RDP` is DPAPI-encrypted
     to the specific Windows account + machine that created it -- a CLIXML
     saved under one account cannot be decrypted by another. Re-run the
     credential prompt once under the new account.
   - If you deployed `PowerShellCustomProfile` in step 4: it reads its own
     DPAPI-protected passwords for the vCenter/Prism connections from
     `C:\ProgramData\PowerShellTranscripts\spw.txt` / `spw2.txt`. Those are
     also account+machine-locked -- recreate them under the new account per
     that repo's README (`Read-Host -AsSecureString` piped through
     `ConvertFrom-SecureString` to each file), and make sure
     `C:\ProgramData\PowerShellTranscripts` exists first.
7. **Verify:** `Get-Module Admin -ListAvailable`, then `Get-AdminConfig` to
   confirm the merged settings look right.

## Configuration

Settings are layered (repo defaults → per-machine → per-user). View the merged
result with `Get-AdminConfig`; manage the override files with `Set-AdminConfig`.

## Exported Commands

The module exports 33 functions and five aliases (`whois`, `Transpose-Object`, `grep`, `Get-ProfilesFromRemoteComputer`, `Remove-ProfilesFromRemoteComputer`).

**Network & DNS:** `Get-Whois` (alias `whois`), `Get-SSLCertificateExpirationDate`
**Files & reports:** `ConvertTo-TransposedObject` (alias `Transpose-Object`), `New-IsoFile`
**Remote system & monitoring:** `Get-SystemUptime`, `Get-SystemInfo`, `Get-Profiles` (alias `Get-ProfilesFromRemoteComputer`), `Remove-Profiles` (alias `Remove-ProfilesFromRemoteComputer`)
**Credentials:** `Test-Credential`, `Get-MyCredential`
**Active Directory:** `Find-ADUser`, `Get-ADUserGroupMembership`
**VMware / Nutanix / Hyper-V:** `Find-VMByIPExact`, `Find-VMByIPLike`, `Get-VMInfo`, `Connect-HyperVHost`, `Disconnect-HyperVHost`, `Get-HyperVSession`, `Get-HyperVHostFromAD`
**Sessions:** `Clear-LoggedOnSessions`, `Get-LoggedOnSessions`
**Remote access & enablement:** `Enable-RemoteDesktop`, `Enable-WinRM`, `Enable-WinRMSSL`, `Start-RDP`
**Workstation / server ops:** `Restart-ComputerAndPing`, `Stop-ComputerAndPing`, `Update-PowerShell`
**Configuration:** `Get-AdminConfig`, `Set-AdminConfig`

## Command Reference

### Network and DNS

#### `Get-Whois`
- Looks up RDAP WHOIS data for a domain.
- Returns domain status, registrar, nameservers, events, and DNSSEC status.
- Alias: `whois`

```powershell
Get-Whois -Domain "example.com"
```

#### `Get-SSLCertificateExpirationDate`
- Connects to a host on port 443 and returns the SSL certificate expiration date.

```powershell
Get-SSLCertificateExpirationDate -url "www.example.com"
```

### Files and Reports

#### `ConvertTo-TransposedObject` (alias `Transpose-Object`)
- Converts object properties from columns into rows.
- Useful for rotating output before exporting or viewing in GridView.

```powershell
Get-Process | Select -First 1 | Transpose-Object | Out-GridView
```

#### `New-IsoFile`
- Creates an ISO disc image from provided source files or folders.
- Supports boot image options when a boot file is supplied.

```powershell
New-IsoFile "C:\tools","C:\Downloads\utils" -Path "C:\temp\MyImage.iso"
```

### Remote System and Monitoring

#### `Get-SystemUptime`
- Retrieves operating system boot and version details from a remote computer.

```powershell
Get-SystemUptime -ComputerName Server01
```

#### `Get-SystemInfo`
- Collects comprehensive system details from a remote computer (via CIM/WS-Management).
- Reports hardware, OS, memory, network, and common port status.

```powershell
Get-SystemInfo -ComputerName Server01
```

#### `Get-Profiles` (alias `Get-ProfilesFromRemoteComputer`)
- Lists unloaded, non-special local user profiles on a computer. Defaults to the
  local computer; pass `-ComputerName` for a remote one.

```powershell
Get-Profiles -ComputerName Workstation01
```

#### `Remove-Profiles` (alias `Remove-ProfilesFromRemoteComputer`)
- Removes unloaded local user profiles from a computer.
- Called standalone with `-ComputerName`, it removes every candidate profile on
  that computer. Piped from `Get-Profiles` (optionally filtered first), it
  removes only the profiles that were piped in.

```powershell
Remove-Profiles -ComputerName Workstation01

# Or filter first, then remove only the matches:
Get-Profiles -ComputerName Workstation01 |
    Where-Object { $_.LastUseTime -lt (Get-Date).AddDays(-90) } |
    Remove-Profiles
```

### Credentials and Security

#### `Test-Credential`
- Validates a `PSCredential` against Domain, Machine, or ApplicationDirectory.

```powershell
$cred = Get-Credential
Test-Credential -credential $cred -context Domain
```

#### `Get-MyCredential`
- Loads a stored credential XML file or prompts to save one if missing.

```powershell
Get-MyCredential -CredPath "C:\secure\mycredential.xml"
```

### Active Directory

#### `Find-ADUser`
- Searches Active Directory for enabled users by partial username, name, or display name using ANR.

```powershell
Find-ADUser "tim"
"tim" | Find-ADUser
```

#### `Get-ADUserGroupMembership`
- Returns the AD groups a user is a direct member of, sorted by name.
- `-GridView` shows all enabled users in a grid and returns the selected user's
  groups (replaces the former `Get-ADUserGroupMembership_OGV`).

```powershell
Get-ADUserGroupMembership -UserName jdoe
'jdoe' | Get-ADUserGroupMembership
Get-ADUserGroupMembership -GridView
```

### VMware / Nutanix / Hyper-V VM Operations

> These functions require VMware PowerCLI, Nutanix Prism PS, or the Hyper-V module
> and assume connections are already established (see your profile's
> `Connect-VIServer` / `Connect-PrismCentral` / `Connect-HyperVHost`).

#### `Connect-HyperVHost` / `Get-HyperVSession` / `Disconnect-HyperVHost`
- Hyper-V has no ambient connection, so its hosts are "mounted" as CIM sessions the
  VM-info functions reuse. `Connect-HyperVHost` opens them (call it from your profile
  beside `Connect-VIServer`/`Connect-PrismCentral`); `Get-HyperVSession` lists them;
  `Disconnect-HyperVHost` closes them.
- Host list sources: `-ComputerName` (explicit), `-FromAD` (discover from AD via
  `Get-HyperVHostFromAD`), or `(Get-AdminConfig).HyperVHosts` (config fallback).
  For failover clusters, list every node -- clustered VMs are deduped by VM id.
- `-FromAD` is the zero-maintenance option and the recommended profile call: it
  finds the "Microsoft Hyper-V" service connection point each host publishes in AD,
  so new hosts appear automatically. Use `-Server` for a different domain/forest.

```powershell
Connect-HyperVHost -FromAD -Server hci.pvt   # discover + mount all hosts (recommended)
Get-HyperVSession                            # confirm what's mounted
Get-HyperVHostFromAD -Server hci.pvt         # just list what AD knows about

# Explicit / config alternatives:
Connect-HyperVHost -ComputerName hv01,hv02
Set-AdminConfig -Name HyperVHosts -Value @('hv01','hv02')
Connect-HyperVHost                           # mounts the configured hosts
```

#### `Get-VMInfo`
- Lists VM info from connected vCenter(s), Prism Central(s), and mounted Hyper-V
  host(s), normalized into a single object shape. Select by name (default), exact IP
  (`-IPExact`), or partial IP (`-IPLike`). Limit with `-Platform`
  (`All` (default) | `VMware` | `Nutanix` | `HyperV`; `Both` = `All`, back-compat).

```powershell
Get-VMInfo web-01
Get-VMInfo -IPExact 10.1.2.3
Get-VMInfo -IPLike 10.1.2 -Platform Nutanix
Get-VMInfo SERVER01 -Platform HyperV
```

#### `Find-VMByIPExact` / `Find-VMByIPLike`
- Back-compat wrappers over `Get-VMInfo -IPExact` / `-IPLike`.

```powershell
Find-VMByIPExact -IP "10.1.2.3"
Find-VMByIPLike  -IP "10.1.2"
```

### Sessions

#### `Clear-LoggedOnSessions`
- Logs off selected users from a remote computer using `quser` and `Out-GridView`.

#### `Get-LoggedOnSessions`
- Returns logged-on sessions from a remote workstation (`quser`) as objects.
  Read-only — it does not log anyone off. Pipe to `Out-GridView` for the grid view.

```powershell
Get-LoggedOnSessions -ComputerName RDS01
Get-LoggedOnSessions -ComputerName RDS01 | Out-GridView
```

### Remote Access and Service Enablement

#### `Enable-RemoteDesktop`
- Enables Remote Desktop and firewall rules remotely via WinRM.

```powershell
Enable-RemoteDesktop -ComputerName Workstation01
```

#### `Enable-WinRM`
- Enables WinRM remotely using PSExec when needed.

```powershell
Enable-WinRM -ComputerName Workstation01
```

#### `Enable-WinRMSSL`
- Enables WinRM over HTTPS remotely.

```powershell
Enable-WinRMSSL -ComputerName Workstation01
```

#### `Start-RDP`
- Stores credentials with `cmdkey`, creates a temporary `.rdp` file, launches
  `mstsc.exe`, then cleans up the credential and temp file.

```powershell
$cred = Get-Credential
Start-RDP -ComputerName Workstation01 -Cred $cred
```

### Workstation and Server Operations

#### `Restart-ComputerAndPing`
- Restarts a remote computer and launches a ping command to watch its return.

```powershell
Restart-ComputerAndPing -ComputerName Workstation01
```

#### `Stop-ComputerAndPing`
- Shuts down a remote computer and pings it to watch it drop offline.

```powershell
Stop-ComputerAndPing -ComputerName Workstation01
```

#### `Update-PowerShell`
- Updates PowerShell 7 to the latest release. Checks the latest version and skips
  if already current; prefers `winget`, falls back to the official
  `aka.ms/install-powershell.ps1 -UseMSI` bootstrap (`-UseMSI` forces it). The MSI
  path needs an elevated session. Supports `-WhatIf`, `-Preview`, `-Quiet`.
- `-Version x.y.z` installs (or reverts to) an exact version, and `-ListVersions`
  lists recent releases; both delegate to `Install-PowerShell7.ps1` (in-place MSI).
- You update the pwsh you launch next; the current session keeps its version.

```powershell
Update-PowerShell            # update to latest stable if newer
Update-PowerShell -WhatIf    # show what would happen, no install
Update-PowerShell -ListVersions
Update-PowerShell -Version 7.4.6   # install or revert to a specific version
Update-PowerShell -UseMSI -Quiet
```

> `Install-PowerShell7.ps1` (repo root) is a standalone, Windows PowerShell
> 5.1-compatible installer for the same job. Use it to bootstrap PowerShell 7 on a
> 5.1-only machine, or run `-ListVersions` / `-Version` directly.

### Configuration

#### `Get-AdminConfig` / `Set-AdminConfig`
- View the merged module configuration (`Get-AdminConfig`) or write per-machine /
  per-user override values (`Set-AdminConfig`).

## Notes

- Many functions were written for a specific administrative environment and depend
  on available infrastructure.
- Commands ending in `_OGV` use `Out-GridView` for interactive selection.
- `New-IsoFile` uses COM automation and may require Windows-specific support.
- See `CHANGELOG.md` for version history.

## License

This documentation is provided for the `PowerShellAdminModule` codebase.
