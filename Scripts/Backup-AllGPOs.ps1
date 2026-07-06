<#
.SYNOPSIS
Exports an HTML report for every GPO in the domain into a single timestamped folder.

.DESCRIPTION
Reading every GPO's settings requires rights most accounts don't carry day-to-day, so this
script prompts for a Domain Admin credential, validates it with Test-Credential, and relaunches
itself under that identity (via Start-Process -Credential) before calling Get-GPO / Get-GPOReport.
One HTML report per GPO is written into a folder named yyyyMMddHHmm.GPOsByName under -Path.

.PARAMETER Path
Parent directory under which the timestamped GPOsByName folder is created. Defaults to C:\temp.

.PARAMETER AsDA
Internal switch, set automatically when the script relaunches itself under the DA credential.
Do not pass this directly.

.EXAMPLE
.\Backup-AllGPOs.ps1

Prompts for DA credentials, then writes one HTML report per GPO to
C:\temp\<timestamp>.GPOsByName\.

.NOTES
Requires the GroupPolicy module (RSAT: Group Policy Management Tools) and the Admin module
(for Test-Credential / New-FolderNameWithTimestamp).
#>

[CmdletBinding()]
param(
    [string]$Path = 'C:\temp',

    [switch]$AsDA
)

if (-not $AsDA) {
    Import-Module Admin -ErrorAction Stop

    $credDA = Get-Credential -Message 'Enter Domain Admin credentials to back up all GPOs'

    if (-not (Test-Credential -Credential $credDA)) {
        throw 'Credential validation failed -- aborting.'
    }

    $argumentList = @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass',
        '-File', "`"$PSCommandPath`"",
        '-Path', "`"$Path`"",
        '-AsDA'
    )

    Write-Verbose 'Relaunching under the DA credential...'
    Start-Process -FilePath 'pwsh' -Credential $credDA -ArgumentList $argumentList -Wait

    return
}

# From here on we're running as DA (relaunched above).
Import-Module GroupPolicy -ErrorAction Stop
Import-Module Admin -ErrorAction Stop

$folder = New-FolderNameWithTimestamp -Subject 'GPOsByName' -Path $Path

$AllGPOs = Get-GPO -All | Select-Object DisplayName, ModificationTime | Sort-Object DisplayName

$AllGPOs.foreach({
    Get-GPOReport -Name $_.DisplayName -ReportType Html -Path (Join-Path $folder.FullName ($_.DisplayName + '.html'))
})

Write-Host "Wrote $($AllGPOs.Count) GPO report(s) to $($folder.FullName)"
Read-Host 'Done. Press Enter to close'
