function Restart-ComputerAndPing {
    <#
    .SYNOPSIS
        Restarts a computer and opens a continuous ping to watch it return.

    .DESCRIPTION
        Issues Restart-Computer against the target and launches a continuous ping
        in a separate console window so you can watch the host drop and come back.

    .PARAMETER ComputerName
        The computer to restart. Defaults to the local computer.

    .EXAMPLE
        Restart-ComputerAndPing -ComputerName SERVER01

    .OUTPUTS
        None.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )

    if ($PSCmdlet.ShouldProcess($ComputerName, 'Restart computer')) {
        Restart-Computer -ComputerName $ComputerName
        Start-Process cmd.exe -ArgumentList "/c ping $ComputerName -t"
    }
}
