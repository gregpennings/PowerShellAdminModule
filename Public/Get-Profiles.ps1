function Get-Profiles {
    <#
    .SYNOPSIS
        Lists non-loaded, non-special user profiles on a computer.

    .DESCRIPTION
        Queries Win32_UserProfile via a CIM session for profiles that are not
        currently loaded and are not special/system profiles -- i.e. the user
        profiles that are candidates for cleanup. Omit -ComputerName to query
        the local computer.

    .PARAMETER ComputerName
        The computer to query. Defaults to the local computer.

    .EXAMPLE
        Get-Profiles -ComputerName SERVER01

    .EXAMPLE
        Get-Profiles -ComputerName SERVER01 | Where-Object { $_.LastUseTime -lt (Get-Date).AddDays(-90) } | Remove-Profiles
        Filters to profiles unused for 90+ days, then removes just those.

    .OUTPUTS
        CIM Win32_UserProfile instances. Pipe them to Remove-Profiles to remove
        exactly the profiles selected here.
    
    .LINK
    https://gregpennings.github.io/PowerShellAdminModule/Get-Profiles.html
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

Set-Alias -Name Get-ProfilesFromRemoteComputer -Value Get-Profiles
