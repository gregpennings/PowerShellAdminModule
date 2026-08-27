<#
.SYNOPSIS
Exports an HTML report for every GPO in the domain into a single timestamped folder.

.DESCRIPTION
Enumerating and reporting on every GPO requires Domain Admin rights. Run this under an
account that already has them -- no credential prompt or remoting involved.

.PARAMETER Path
Parent directory on this machine under which the timestamped GPOsByName folder is
created. Defaults to C:\temp.

.EXAMPLE
.\Backup-AllGPOs.ps1

Writes one HTML report per GPO to C:\temp\<timestamp>.GPOsByName\ on this machine.

.NOTES
Requires the GroupPolicy module on this machine.
#>

[CmdletBinding()]
param(
    [string]$Path = 'C:\temp'
)

$folderName = "$(Get-Date -Format 'yyyyMMddHHmm').GPOsByName"
$folder = New-Item -ItemType Directory -Path (Join-Path $Path $folderName) -Force

Write-Verbose 'Querying GPOs and building reports...'
$reports = Get-GPO -All | Sort-Object DisplayName | ForEach-Object {
    [pscustomobject]@{
        DisplayName = $_.DisplayName
        Html        = Get-GPOReport -Guid $_.Id -ReportType Html
    }
}

foreach ($report in $reports) {
    Set-Content -Path (Join-Path $folder.FullName ($report.DisplayName + '.html')) -Value $report.Html -Encoding utf8
}

Write-Host "Wrote $($reports.Count) GPO report(s) to $($folder.FullName)"
