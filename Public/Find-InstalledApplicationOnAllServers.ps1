function Find-InstalledApplicationOnAllServers {
    <#
    .SYNOPSIS
        Finds an installed application across all recently-active servers.

    .DESCRIPTION
        Finds enabled server computer objects in AD that were modified in the last
        13 days (a proxy for "active"), queries each for a matching installed
        application via Win32_Product, emits the matches and a count, and exports
        the results to a timestamped CSV.

    .PARAMETER Application
        Text to match against the product name.

    .PARAMETER Path
        Directory for the CSV export. Defaults to the configured DefaultExportPath.

    .EXAMPLE
        Find-InstalledApplicationOnAllServers -Application Sectra

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

    $servers = Get-ADComputer -Filter { (Modified -gt $cutoff) -and (OperatingSystem -like '*server*') -and (Enabled -eq $true) }
    $found   = Get-CimInstance -ComputerName $servers.Name -Query $query -OperationTimeoutSec 60 -ErrorAction SilentlyContinue

    $found | Sort-Object PSComputerName, Name | Select-Object Name, Version, PSComputerName
    Write-Host "Found on $(@($found).Count) computer(s)."
    $found | Export-Csv -Path $report.FullName -NoTypeInformation
    Write-Host "Output saved to $($report.FullName)"
}
