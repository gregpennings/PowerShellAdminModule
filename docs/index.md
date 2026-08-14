---
document type: module
Help Version: 1.0.0.0
HelpInfoUri: 
Locale: en-US
Module Guid: 208cd22a-6a8f-485a-a35d-14b008e01c46
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Admin Module
---

# Admin Module

## Description

Administrative helper functions for VMware, Nutanix, Active Directory, and Windows server/workstation management. (Citrix helpers live in the separate CitrixTools module.)

## Admin

### [Clear-LoggedOnSession](Clear-LoggedOnSession.html)

Logs off user sessions on a remote computer.

### [Connect-HyperVHost](Connect-HyperVHost.html)

"Mounts" one or more Hyper-V hosts by opening CIM sessions the VM-info
functions reuse. The Hyper-V analog of Connect-VIServer / Connect-PrismCentral.

### [ConvertTo-TransposedObject](ConvertTo-TransposedObject.html)

Transpose properties of objects from columns to rows.

### [Disconnect-HyperVHost](Disconnect-HyperVHost.html)

Closes Hyper-V CIM sessions opened by Connect-HyperVHost and drops them
from the module session store.

### [Enable-RemoteDesktop](Enable-RemoteDesktop.html)

Enables Remote Desktop (RDP) on a computer.

### [Enable-WinRM](Enable-WinRM.html)

Enables PowerShell Remoting (WinRM) on a computer using PsExec.

### [Enable-WinRMSSL](Enable-WinRMSSL.html)

Enables WinRM over HTTPS (SSL) on a computer using PsExec.

### [Find-ADUser](Find-ADUser.html)

Finds enabled AD users matching a partial name, username, or display name.

### [Find-VMByIPExact](Find-VMByIPExact.html)

Backward-compatible wrapper. Use Get-VMInfo -IPExact instead.

### [Find-VMByIPLike](Find-VMByIPLike.html)

Backward-compatible wrapper. Use Get-VMInfo -IPLike instead.

### [Get-AdminConfig](Get-AdminConfig.html)

Returns the effective Admin module configuration.

### [Get-ADUserGroupMembership](Get-ADUserGroupMembership.html)

Lists the AD groups a user is a direct member of.

### [Get-CredExpiration](Get-CredExpiration.html)

On-demand credential/certificate expiration checker.

### [Get-HyperVHostFromAD](Get-HyperVHostFromAD.html)

Discovers Hyper-V hosts from Active Directory and returns their DNS host names.

### [Get-HyperVSession](Get-HyperVSession.html)

Returns the Hyper-V CIM sessions currently mounted by Connect-HyperVHost.

### [Get-LoggedOnSession](Get-LoggedOnSession.html)

Returns the logged-on sessions of a computer as objects.

### [Get-MyCredential](Get-MyCredential.html)

Loads a stored PSCredential from a file, creating it on first use.

### [Get-Profile](Get-Profile.html)

Lists non-loaded, non-special user profiles on a computer.

### [Get-SSLCertificateExpirationDate](Get-SSLCertificateExpirationDate.html)

Gets the expiration date of a host's SSL/TLS certificate.

### [Get-SystemInfo](Get-SystemInfo.html)

Gets a broad set of hardware, OS, network, memory, and open-port details for
a computer (local or remote).

### [Get-SystemUptime](Get-SystemUptime.html)

{{ Fill in the Synopsis }}

### [Get-VMInfo](Get-VMInfo.html)

Lists VM info from VMware vCenter(s), Nutanix Prism Central(s), and
Hyper-V host(s).

### [Get-Whois](Get-Whois.html)

Performs an RDAP (modern WHOIS) lookup for a domain.

### [New-FolderNameWithTimestamp](New-FolderNameWithTimestamp.html)

{{ Fill in the Synopsis }}

### [New-IsoFile](New-IsoFile.html)

Creates a new .iso file.

### [Remove-Profile](Remove-Profile.html)

Removes non-loaded, non-special user profiles from a computer.

### [Restart-ComputerAndPing](Restart-ComputerAndPing.html)

Restarts a computer and opens a continuous ping to watch it return.

### [Select-StringFromObject](Select-StringFromObject.html)

Greps the formatted text of pipeline objects -- Out-String -Stream | Select-String.

### [Set-AdminConfig](Set-AdminConfig.html)

Sets a persistent Admin module configuration value.

### [Start-RDP](Start-RDP.html)

Opens an RDP session to a computer using a supplied credential.

### [Stop-ComputerAndPing](Stop-ComputerAndPing.html)

Shuts down a computer and opens a continuous ping to watch it drop.

### [Test-Credential](Test-Credential.html)

Validates a PSCredential against the domain, local machine, or an AD LDS instance.

### [Update-PowerShell](Update-PowerShell.html)

Updates PowerShell 7 to the latest release using the recommended installer,
with a version check, an elevation check, and -WhatIf support.

### [Update-VMInfoCache](Update-VMInfoCache.html)

Rebuilds the on-disk cache that Get-VMInfo reads from by default.

