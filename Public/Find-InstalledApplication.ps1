function Find-InstalledApplication {
    <#
    .SYNOPSIS
        Finds an installed application (by name) on a computer.

    .DESCRIPTION
        Queries Win32_Product via CIM for products whose name matches the supplied
        text, returning the product name and version.

    .PARAMETER ComputerName
        The computer to query. Defaults to the local computer.

    .PARAMETER Application
        Text to match against the product name (wildcard match via LIKE).

    .EXAMPLE
        Find-InstalledApplication -ComputerName SERVER01 -Application Sectra

    .OUTPUTS
        PSCustomObject (Name, Version).

    .NOTES
        Win32_Product is slow and can trigger MSI self-repair; querying it is a
        known anti-pattern, retained here for compatibility.
    #>
    [CmdletBinding()]
    param(
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory)]
        [string]$Application
    )

    $query = "SELECT Name, Version FROM Win32_Product WHERE Name LIKE '%$Application%'"
    Get-CimInstance -ComputerName $ComputerName -Query $query -OperationTimeoutSec 60 |
        Select-Object Name, Version
}
