function Get-ProfilesFromRemoteComputer {
    <#
    .SYNOPSIS
        Lists non-loaded, non-special user profiles on a computer.

    .DESCRIPTION
        Queries Win32_UserProfile via a CIM session for profiles that are not
        currently loaded and are not special/system profiles -- i.e. the user
        profiles that are candidates for cleanup.

    .PARAMETER ComputerName
        The computer to query. Defaults to the local computer.

    .EXAMPLE
        Get-ProfilesFromRemoteComputer -ComputerName SERVER01

    .OUTPUTS
        CIM Win32_UserProfile instances.
    #>
    [CmdletBinding()]
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )

    $session = New-CimSession -ComputerName $ComputerName
    try {
        Get-CimInstance -CimSession $session -Query "SELECT * FROM Win32_UserProfile WHERE Loaded = FALSE AND Special = FALSE"
    } finally {
        Remove-CimSession $session
    }
}
