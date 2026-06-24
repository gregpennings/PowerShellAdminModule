function Get-LoggedOnUser {
    <#
    .SYNOPSIS
        Gets the interactively logged-on user for one or more computers.

    .DESCRIPTION
        Reads the UserName property of Win32_ComputerSystem via CIM for each target.
        This reflects the console / primary interactive session only; it does not
        enumerate all RDP sessions (use quser or Clear-LoggedOnSessions for that).

    .PARAMETER ComputerName
        One or more computers to query. Defaults to the local computer. Accepts
        pipeline input.

    .EXAMPLE
        Get-LoggedOnUser -ComputerName SERVER01

    .EXAMPLE
        'WS01','WS02' | Get-LoggedOnUser

    .OUTPUTS
        PSCustomObject (ComputerName, UserName).
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )
    process {
        foreach ($comp in $ComputerName) {
            [PSCustomObject]@{
                ComputerName = $comp
                UserName     = (Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $comp).UserName
            }
        }
    }
}
