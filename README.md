# PowerShell Admin Module

`Admin` is a PowerShell module of administrative utilities for remote systems,
Active Directory, VMware/Nutanix/Hyper-V infrastructure, credential handling, and
general system administration.

> Citrix helpers were moved out into the separate **CitrixTools** module (they
> require the `Citrix.*.Admin.V*` snap-ins, which are Windows PowerShell 5.1 only).

## Installation

1. Place the `Admin` module folder in a PowerShell module path.
   - Example: `C:\Program Files\PowerShell\7\Modules\Admin`
2. Import the module in your PowerShell session:
   ```powershell
   Import-Module Admin
   ```
3. Optionally add `Import-Module Admin` to your PowerShell profile.
   - Example profile path: `C:\Users\<username>\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`

## Requirements

- PowerShell 5.1 or higher
- `ActiveDirectory` module for AD-related commands
- VMware PowerCLI modules for VMware commands (`VMware.VimAutomation.Core` and related cmdlets)
- Nutanix Prism PowerShell module for Nutanix VM commands (`Nutanix.Prism.PS.Cmds`)
- `Hyper-V` module for Hyper-V VM commands (Windows feature; soft dependency -- the
  module imports without it, but the Hyper-V code paths require it)
- Internet access for `Get-Whois` and SSL certificate checks

## Configuration

Settings are layered (repo defaults → per-machine → per-user). View the merged
result with `Get-AdminConfig`; manage the override files with `Set-AdminConfig`.

## Exported Commands

The module exports 30 functions and three aliases (`whois`, `Transpose-Object`, `grep`).

**Network & DNS:** `Get-Whois` (alias `whois`), `Get-SSLCertificateExpirationDate`
**Files & reports:** `ConvertTo-TransposedObject` (alias `Transpose-Object`), `New-IsoFile`
**Remote system & monitoring:** `Get-Uptime`, `Get-SystemInfo`, `Get-ProfilesFromRemoteComputer`, `Remove-ProfilesFromRemoteComputer`
**Credentials:** `Test-Credential`, `Get-MyCredential`
**Active Directory:** `Find-ADUser`, `Get-ADUserGroupMembership`
**VMware / Nutanix / Hyper-V:** `Find-VMByIPExact`, `Find-VMByIPLike`, `Get-VMInfo`, `Get-VMInfoAllVMs`, `Connect-HyperVHost`, `Disconnect-HyperVHost`, `Get-HyperVSession`
**Sessions:** `Clear-LoggedOnSessions`, `Get-LoggedOnSessions`
**Remote access & enablement:** `Enable-RemoteDesktop`, `Enable-WinRM`, `Enable-WinRMSSL`, `Start-RDP`
**Workstation / server ops:** `Restart-ComputerAndPing`, `Stop-ComputerAndPing`
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

#### `Get-Uptime`
- Retrieves operating system boot and version details from a remote computer.

```powershell
Get-Uptime -ComputerName Server01
```

#### `Get-SystemInfo`
- Collects comprehensive system details from a remote computer (via CIM/WS-Management).
- Reports hardware, OS, memory, network, and common port status.

```powershell
Get-SystemInfo -ComputerName Server01
```

#### `Get-ProfilesFromRemoteComputer`
- Lists unloaded local user profiles on a remote computer.

```powershell
Get-ProfilesFromRemoteComputer -ComputerName Workstation01
```

#### `Remove-ProfilesFromRemoteComputer`
- Removes unloaded local user profiles from a remote computer.

```powershell
Remove-ProfilesFromRemoteComputer -ComputerName Workstation01
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
- With no `-ComputerName`, hosts come from `(Get-AdminConfig).HyperVHosts`. Set the
  list once with `Set-AdminConfig`. For failover clusters, list every node --
  clustered VMs are deduped by VM id.

```powershell
Set-AdminConfig -Name HyperVHosts -Value @('hv01','hv02','clusternodeA','clusternodeB')
Connect-HyperVHost                 # mounts the configured hosts
Get-HyperVSession                  # confirm what's mounted
Connect-HyperVHost -ComputerName wrkgrp-hv -Credential (Get-Credential)
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

#### `Get-VMInfoAllVMs`
- Returns full inventory for all VMware, Nutanix, and/or Hyper-V VMs to the pipeline.
- `-ExportCsv` writes one timestamped CSV per platform and returns the path(s).

```powershell
Get-VMInfoAllVMs
Get-VMInfoAllVMs -Platform VMware | Where-Object PowerState -eq 'PoweredOn'
Get-VMInfoAllVMs -ExportCsv
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
