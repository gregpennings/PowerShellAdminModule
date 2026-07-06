<#
.SYNOPSIS
Exports an HTML report for every GPO in the domain into a single timestamped folder.

.DESCRIPTION
Enumerating and reporting on every GPO requires Domain Admin rights. This org's Tier-0
hardening denies local interactive logon for DA accounts on regular workstations and
also blocks NTLM-only auth, so neither Start-Process -Credential nor runas /netonly can
"borrow" DA rights locally. Instead, this script prompts for a DA credential, validates
it, and uses Invoke-Command to run Get-GPO / Get-GPOReport directly on a domain
controller -- a Kerberos network logon DA accounts are permitted to make. Each report's
HTML content is returned over the remoting session and written locally; nothing is ever
written to disk on the domain controller.

.PARAMETER Path
Parent directory on this machine under which the timestamped GPOsByName folder is
created. Defaults to C:\temp.

.PARAMETER DomainController
The domain controller to run Get-GPO / Get-GPOReport on. Defaults to hcidaldc05.hci.pvt.

.EXAMPLE
.\Backup-AllGPOs.ps1

Prompts for DA credentials, then writes one HTML report per GPO to
C:\temp\<timestamp>.GPOsByName\ on this machine.

.NOTES
Requires the Admin module (for Test-Credential / New-FolderNameWithTimestamp) and WinRM
reachability to the target domain controller. The GroupPolicy module only needs to be
present on the domain controller, not on this machine.
#>

[CmdletBinding()]
param(
    [string]$Path = 'C:\temp',

    [string]$DomainController = 'hcidaldc05.hci.pvt'
)

Import-Module Admin -ErrorAction Stop

$credDA = Get-Credential -Message "Enter Domain Admin credentials to back up all GPOs from $DomainController"

if (-not (Test-Credential -Credential $credDA)) {
    throw 'Credential validation failed -- aborting.'
}

$folder = New-FolderNameWithTimestamp -Subject 'GPOsByName' -Path $Path

Write-Verbose "Querying GPOs and building reports on $DomainController..."
$reports = Invoke-Command -ComputerName $DomainController -Credential $credDA -ScriptBlock {
    Get-GPO -All | Sort-Object DisplayName | ForEach-Object {
        [pscustomobject]@{
            DisplayName = $_.DisplayName
            Html        = Get-GPOReport -Guid $_.Id -ReportType Html
        }
    }
}

foreach ($report in $reports) {
    Set-Content -Path (Join-Path $folder.FullName ($report.DisplayName + '.html')) -Value $report.Html -Encoding utf8
}

Write-Host "Wrote $($reports.Count) GPO report(s) to $($folder.FullName)"
