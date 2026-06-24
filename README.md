# PowerShell Admin Module

This repository contains a PowerShell administration module named `Admin.psm1` with a broad set of utilities for remote systems, Active Directory, VMware/Nutanix infrastructure, Citrix session management, credential handling, and general system administration.

## Installation

1. Place the `Admin` module folder in a PowerShell module path.
   - Example: `C:\Program Files\PowerShell\7\Modules\Admin`
2. Import the module in your PowerShell session:
   ```powershell
   Import-Module Admin
   ```
3. Optionally add `Import-Module Admin` to your PowerShell profile.
   - Example profile path: `C:\Users\<username>\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`

> Notes from the repository: drop the PowerShell profile under `C:\Users\admgpennings\Documents\PowerShell` and place the `Admin` module folder under `Program Files\PowerShell\7\Modules`.

## Requirements

- PowerShell 5.1 or higher
- `ActiveDirectory` module for AD-related commands
- VMware PowerCLI modules for VMware commands (`VMware.VimAutomation.Core` and related cmdlets)
- Nutanix Prism PowerShell module for Nutanix VM commands (`Nutanix.Prism.PS.Cmds`)
- Citrix administrative snap-ins for Citrix session and machine management
- Internet access for `Get-Whois`, `Test-URI`, and SSL certificate checks

## General Usage

Once imported, the module exposes a set of functions and one alias:

- `Get-Whois` / alias `whois`
- `Transpose-Object`
- `Find-FilesContainingText`
- `New-FileNameWithTimestamp`
- `Get-SSLCertificateExpirationDate`
- `Get-RemoteDiskUsage`
- `Get-RebootHistory`
- `Get-LoggedOnUser`
- `Find-VMByIPExact`
- `Find-VMByIPLike`
- `Get-VMInfo`
- `Get-VMInfoAllVMs_CSV`
- `Test-Credential`
- `Find-InstalledApplicationOnAllWorkstations`
- `Find-InstalledApplicationOnAllServers`
- `Find-InstalledApplication`
- `Find-ADUser`
- `Remove-VmAudioDevice_OGV`
- `Get-ADUserGroupMembership`
- `Get-ADUserGroupMembership_OGV`
- `Get-ADGroupMember_OGV`
- `Get-CertificateCryptographicProvider_OGV`
- `Get-VIEventPlus`
- `Get-MotionHistory`
- `Test-URI`
- `Get-Uptime`
- `Remove-Snapshot_OGV`
- `Get-ProfilesFromRemoteComputer`
- `Remove-ProfilesFromRemoteComputer`
- `Get-MyCredential`
- `Export-Credential`
- `Get-IndependentDrives`
- `Get-CitrixSessionsAll`
- `Clean-CitrixDisconnectedSessions`
- `Clean-CitrixSessions1Hr`
- `Clear-CitrixLocalPassword`
- `Get-RDUserLogoff_OGV`
- `Invoke-RDUserLogoff_OGV`
- `Clear-LoggedOnSessions_OGV`
- `Clear-LoggedOnSessions`
- `Enable-RemoteDesktop`
- `Enable-WinRM`
- `Enable-WinRMSSL`
- `Get-AllServersInComputersContainer`
- `Get-CitrixGhostSessions`
- `Get-CitrixLoggingOffSessions`
- `Get-CitrixOldDisconnectedSessions`
- `Get-CitrixSessons1Hr`
- `Get-LoggedOnSessions_OGV`
- `Get-SystemInfo`
- `Get-CitrixUnregisteredMachines`
- `Clear-AutoRunCD`
- `Clean-DesktopIcons`
- `Restart-CitrixUnregistered_OGV`
- `Get-CitrixUnregistered_OGV`
- `Restart-ComputerAndPing`
- `Set-CitrixHungSesstionToGhost_OGV`
- `Stop-ComputerAndPing`
- `Start-RDP`
- `New-IsoFile`

## Command Reference

### 1. Network and DNS Utilities

#### `Get-Whois`
- Looks up RDAP WHOIS data for a domain.
- Returns domain status, registrar, nameservers, events, and DNSSEC status.
- Alias: `whois`

Example:
```powershell
Get-Whois -Domain "example.com"
```

#### `Test-URI`
- Tests an HTTP/S URL or URI.
- Returns `True`/`False` by default or detailed response metadata with `-Detail`.

Example:
```powershell
Test-URI https://example.com
Test-URI https://example.com -Detail
```

#### `Get-SSLCertificateExpirationDate`
- Connects to a host on port 443 and returns SSL certificate expiration date.

Example:
```powershell
Get-SSLCertificateExpirationDate -url "www.example.com"
```

### 2. File and Report Helpers

#### `Transpose-Object`
- Converts object properties from columns into rows.
- Useful for rotating output before exporting or viewing in GridView.

Example:
```powershell
Get-Process | Select -First 1 | Transpose-Object | Out-GridView
```

#### `Find-FilesContainingText`
- Searches recursively for files containing a text pattern.
- Returns matching filenames.

Example:
```powershell
Find-FilesContainingText -Path C:\Scripts -Pattern "Execution Policy"
```

#### `New-FileNameWithTimestamp`
- Generates a timestamped filename and returns a `System.IO.FileInfo` object.
- Supports custom subject, extension, path, and optional empty file creation.

Example:
```powershell
New-FileNameWithTimestamp -Subject "SnapshotList" -Extension "csv" -Path "C:\temp" -IncludeSeconds -CreateEmptyFile
```

#### `New-IsoFile`
- Creates an ISO disc image from provided source files or folders.
- Supports boot image options when a boot file is supplied.

Example:
```powershell
New-IsoFile "C:\tools","C:\Downloads\utils" -Path "C:\temp\MyImage.iso"
```

### 3. Remote System and Monitoring

#### `Get-RemoteDiskUsage`
- Retrieves disk usage statistics from a remote Windows computer.
- Reports drive size, used/free space, and percentages.

Example:
```powershell
Get-RemoteDiskUsage -ComputerName Server01
```

#### `Get-RebootHistory`
- Returns reboot and unexpected shutdown history from the System event log.
- Supports `-ComputerName`, `-DaysFromToday`, and `-MaxEvents`.

Example:
```powershell
Get-RebootHistory -ComputerName Server01 -DaysFromToday 30 -MaxEvents 10
```

#### `Get-LoggedOnUser`
- Returns the currently logged-on user from `Win32_ComputerSystem`.

Example:
```powershell
Get-LoggedOnUser -ComputerName Workstation01
```

#### `Get-Uptime`
- Retrieves operating system boot and version details from a remote computer.

Example:
```powershell
Get-Uptime -ComputerName Server01
```

#### `Get-ProfilesFromRemoteComputer`
- Lists unloaded local user profiles on a remote computer.

Example:
```powershell
Get-ProfilesFromRemoteComputer -ComputerName Workstation01
```

#### `Remove-ProfilesFromRemoteComputer`
- Removes unloaded local user profiles from a remote computer.

Example:
```powershell
Remove-ProfilesFromRemoteComputer -ComputerName Workstation01
```

#### `Get-SystemInfo`
- Collects comprehensive system details from a remote computer using WMI.
- Reports hardware, OS, memory, network, and common port status.

Example:
```powershell
Get-SystemInfo -ComputerName Server01
```

### 4. Credentials and Security

#### `Test-Credential`
- Validates a `PSCredential` against Domain, Machine, or ApplicationDirectory.

Example:
```powershell
$cred = Get-Credential
Test-Credential -credential $cred -context Domain
```

#### `Get-MyCredential`
- Loads a stored credential XML file or prompts to save one if missing.

Example:
```powershell
Get-MyCredential -CredPath "C:\secure\mycredential.xml"
```

#### `Export-Credential`
- Saves a `PSCredential` object to a secure XML file.

Example:
```powershell
$cred = Get-Credential
Export-Credential $cred C:\secure\mycredential.xml
```

### 5. Active Directory

#### `Find-ADUser`
- Searches Active Directory for enabled users by partial username, name, or display name using ANR.

Example:
```powershell
Find-ADUser "tim"
"tim" | Find-ADUser
```

#### `Get-ADUserGroupMembership`
- Returns group membership for a specified AD user.

Example:
```powershell
Get-ADUserGroupMembership -UserName jdoe
```

#### `Get-ADUserGroupMembership_OGV`
- Collects group membership for enabled AD users and displays results in Out-GridView.

Example:
```powershell
Get-ADUserGroupMembership_OGV
```

#### `Get-ADGroupMember_OGV`
- Displays members of a selected AD group in Out-GridView.

Example:
```powershell
Get-ADGroupMember_OGV
```

### 6. VMware / Nutanix VM Operations

> Many functions require VMware PowerCLI or Nutanix Prism PS modules.

#### `Find-VMByIPExact`
- Searches VMware and Nutanix VMs for an exact IP match.

Example:
```powershell
Find-VMByIPExact -IP "10.1.2.3"
```

#### `Find-VMByIPLike`
- Searches VMware and Nutanix VMs for partial IP matches.

Example:
```powershell
Find-VMByIPLike -IP "10.1.2"
```

#### `Get-VMInfo`
- Returns detailed VMware and Nutanix VM information for a given VM name.

Example:
```powershell
Get-VMInfo -VM "web-01"
```

#### `Get-VMInfoAllVMs_CSV`
- Exports all VMware and Nutanix VM inventory to CSV files under `C:\temp`.

Example:
```powershell
Get-VMInfoAllVMs_CSV
```

#### `Remove-VmAudioDevice_OGV`
- Identifies VMs that contain an audio device and removes it after shutdown.
- Uses Out-GridView for VM selection.

Example:
```powershell
Remove-VmAudioDevice_OGV
```

#### `Get-IndependentDrives`
- Lists powered-on VMware VMs with Independent Persistent disks.

Example:
```powershell
Get-IndependentDrives
```

#### `Get-VIEventPlus`
- Returns vSphere events with filtering for entity, event type, user, timespan, and more.

Example:
```powershell
Get-VIEventPlus -Entity $vm -EventType "VmMigratedEvent" -Start (Get-Date).AddDays(-7)
```

#### `Get-MotionHistory`
- Reports vMotion/svMotion history for VMware VMs or containers.

Example:
```powershell
Get-VM -Name web-01 | Get-MotionHistory -Days 7
```

#### `Remove-Snapshot_OGV`
- Uses Out-GridView to select and remove a snapshot from a VM.

Example:
```powershell
Remove-Snapshot_OGV
```

### 7. Citrix Session Management

> These commands require Citrix administrative snap-ins and environment-specific controllers.

#### `Get-CitrixSessionsAll`
- Shows all Citrix Broker sessions with host machine, state, and username.

#### `Clean-CitrixDisconnectedSessions`
- Stops disconnected Citrix sessions and optionally restarts hung machines.

#### `Clean-CitrixSessions1Hr`
- Stops disconnected Citrix sessions older than one hour.

#### `Clear-CitrixLocalPassword`
- Uses PSExec to clear Citrix local saved passwords on a remote machine.

#### `Get-RDUserLogoff_OGV`
- Shows remote desktop user sessions in Out-GridView for selection.

#### `Invoke-RDUserLogoff_OGV`
- Logs off selected remote desktop sessions.

#### `Clear-LoggedOnSessions_OGV`
- Displays session list via Out-GridView and logs off selected users.

#### `Clear-LoggedOnSessions`
- Logs off selected users from a remote computer using `quser` and `Out-GridView`.

#### `Get-CitrixGhostSessions`
- Identifies older Citrix sessions likely needing hidden state.

#### `Get-CitrixLoggingOffSessions`
- Displays Citrix sessions currently in logoff progress.

#### `Get-CitrixOldDisconnectedSessions`
- Lists older disconnected Citrix sessions and app state details.

#### `Get-CitrixSessons1Hr`
- Lists Citrix sessions older than one hour, including disconnected and active/no-app sessions.

#### `Get-CitrixUnregisteredMachines`
- Reports Citrix machines states that are unregistered and not in maintenance.

#### `Restart-CitrixUnregistered_OGV`
- Presents unregistered Citrix machines for restart.

#### `Get-CitrixUnregistered_OGV`
- Displays unregistered Citrix machines in Out-GridView.

#### `Set-CitrixHungSesstionToGhost_OGV`
- Hides selected hung Citrix sessions using Out-GridView.

### 8. Remote Access and Service Enablement

#### `Enable-RemoteDesktop`
- Enables Remote Desktop and firewall rules remotely via WinRM.

Example:
```powershell
Enable-RemoteDesktop -ComputerName Workstation01
```

#### `Enable-WinRM`
- Enables WinRM remotely using PSExec when needed.

Example:
```powershell
Enable-WinRM -ComputerName Workstation01
```

#### `Enable-WinRMSSL`
- Enables WinRM over HTTPS remotely.

Example:
```powershell
Enable-WinRMSSL -ComputerName Workstation01
```

#### `Start-RDP`
- Stores credentials with `cmdkey`, creates a temporary `.rdp` file, and launches `mstsc.exe`.
- Cleans up the credential and temporary file after startup.

Example:
```powershell
$cred = Get-Credential
Start-RDP -ComputerName Workstation01 -Cred $cred
```

### 9. Workstation and Server Operations

#### `Restart-ComputerAndPing`
- Restarts a remote computer and launches a ping command to watch its return.

Example:
```powershell
Restart-ComputerAndPing -ComputerName Workstation01
```

#### `Stop-ComputerAndPing`
- Stops a remote computer and pings it next.

Example:
```powershell
Stop-ComputerAndPing -ComputerName Workstation01
```

#### `Clear-AutoRunCD`
- Disables autorun for removable media on a remote workstation by updating registry values.

#### `Clean-DesktopIcons`
- Removes desktop icons by modifying the selected user registry settings on a remote system.

### 10. Special Utilities

#### `Get-AllServersInComputersContainer`
- Queries Active Directory for servers in the `CN=Computers` container.

#### `Get-CitrixLoggingOffSessions`
- Shows Citrix sessions currently in logoff progress.

#### `Get-LoggedOnSessions_OGV`
- Displays logged-on sessions from a remote workstation with `quser` in an interactive grid view.

#### `Get-CertificateCryptographicProvider_OGV`
- Prompts for certificate selection and returns cryptographic provider details for the selected certificate.

## Example Workflows

- Search for text across files:
  ```powershell
  Find-FilesContainingText -Path C:\scripts -Pattern "Error"
  ```
- Generate a timestamped CSV file path:
  ```powershell
  (New-FileNameWithTimestamp -Subject "Inventory" -Extension "csv").FullName
  ```
- Get remote disk usage:
  ```powershell
  Get-RemoteDiskUsage -ComputerName fileserver01
  ```
- Find a VM by IP:
  ```powershell
  Find-VMByIPLike -IP "192.168.1"
  ```

## Notes

- Many functions were written for a specific administrative environment and depend on available infrastructure.
- The module includes a mixture of production-ready utilities and interactive helper commands.
- Commands ending in `_OGV` are designed to use `Out-GridView` for selection.
- `New-IsoFile` uses COM automation and may require Windows-specific support.

## License

This documentation is provided for the `PowerShellAdminModule` codebase.
