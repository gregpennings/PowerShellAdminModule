function Find-InstalledApplicationOnAllWorkstations {
    <#
    .SYNOPSIS
        Finds an installed application across all recently-active workstations.

    .DESCRIPTION
        Finds enabled non-server computer objects in AD (excluding names beginning
        with "ctx") that were modified in the last 13 days (a proxy for "active"),
        queries each for a matching installed application via Win32_Product, emits
        the matches and a count, and exports the results to a timestamped CSV.

    .PARAMETER Application
        Text to match against the product name.

    .PARAMETER Path
        Directory for the CSV export. Defaults to the configured DefaultExportPath.

    .EXAMPLE
        Find-InstalledApplicationOnAllWorkstations -Application Sectra

    .OUTPUTS
        PSCustomObject (Name, Version, PSComputerName); also writes a CSV.

    .NOTES
        Win32_Product is slow and can trigger MSI self-repair; retained for compatibility.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Application,

        [string]$Path = $script:AdminConfig.DefaultExportPath
    )

    $report = New-FileNameWithTimestamp -Subject $Application -Extension csv -Path $Path -IncludeSeconds
    $query  = "SELECT Name, Version FROM Win32_Product WHERE Name LIKE '%$Application%'"
    $cutoff = (Get-Date).AddDays(-13)

    $workstations = Get-ADComputer -Filter { (Modified -gt $cutoff) -and (OperatingSystem -notlike '*server*') -and (Enabled -eq $true) -and (Name -notlike 'ctx*') }
    $found        = Get-CimInstance -ComputerName $workstations.Name -Query $query -OperationTimeoutSec 60 -ErrorAction SilentlyContinue

    $found | Sort-Object PSComputerName, Name | Select-Object Name, Version, PSComputerName
    Write-Host "Found on $(@($found).Count) computer(s)."
    $found | Export-Csv -Path $report.FullName -NoTypeInformation
    Write-Host "Output saved to $($report.FullName)"
}
