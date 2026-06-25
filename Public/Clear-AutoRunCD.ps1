function Clear-AutoRunCD {
    <#
    .SYNOPSIS
        Disables CD/DVD AutoRun on a remote computer.

    .DESCRIPTION
        Sets the NoDriveTypeAutoRun Explorer policy value under HKLM on the target
        computer (over a PowerShell session) to disable AutoRun for the relevant
        drive types.

    .PARAMETER ComputerName
        The target computer.

    .EXAMPLE
        Clear-AutoRunCD -ComputerName WS01

    .OUTPUTS
        None.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    if ($PSCmdlet.ShouldProcess($ComputerName, 'Disable CD AutoRun (NoDriveTypeAutoRun)')) {
        $session = New-PSSession -ComputerName $ComputerName
        try {
            Invoke-Command -Session $session -ScriptBlock {
                New-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' `
                    -Name 'NoDriveTypeAutoRun' -Value 177 -PropertyType DWord -Force | Out-Null
            }
        } finally {
            Remove-PSSession $session
        }
    }
}
