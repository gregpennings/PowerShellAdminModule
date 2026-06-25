function Stop-ComputerAndPing {
    <#
    .SYNOPSIS
        Shuts down a computer and opens a continuous ping to watch it drop.

    .DESCRIPTION
        Issues Stop-Computer against the target and launches a continuous ping in a
        separate console window so you can watch the host go offline.

    .PARAMETER ComputerName
        The computer to shut down. Defaults to the local computer.

    .EXAMPLE
        Stop-ComputerAndPing -ComputerName SERVER01

    .OUTPUTS
        None.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )

    if ($PSCmdlet.ShouldProcess($ComputerName, 'Shut down computer')) {
        Stop-Computer -ComputerName $ComputerName
        Start-Process cmd.exe -ArgumentList "/c ping $ComputerName -t"
    }
}
