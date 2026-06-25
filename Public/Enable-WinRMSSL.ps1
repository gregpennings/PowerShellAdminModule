function Enable-WinRMSSL {
    <#
    .SYNOPSIS
        Enables WinRM over HTTPS (SSL) on a computer using PsExec.

    .DESCRIPTION
        Runs 'winrm.cmd quickconfig -transport:https' remotely via PsExec (under the
        SYSTEM account) to configure the WinRM HTTPS listener. Requires PsExec
        (see Get-AdminConfig / Set-AdminConfig PsExecPath), SMB/RPC reachability,
        and a suitable server certificate on the target for the HTTPS listener.

    .PARAMETER ComputerName
        The target computer. Defaults to the local computer.

    .PARAMETER PsExecPath
        Path to the PsExec executable. Defaults to the configured PsExecPath.

    .EXAMPLE
        Enable-WinRMSSL -ComputerName SERVER01
        Configures the WinRM HTTPS listener on SERVER01.

    .OUTPUTS
        None.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [string]$PsExecPath   = $script:AdminConfig.PsExecPath
    )

    if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
        Write-Warning "$ComputerName is not responding to ping."
        return
    }

    if ($PSCmdlet.ShouldProcess($ComputerName, "Enable WinRM over HTTPS via PsExec")) {
        & $PsExecPath -s "\\$ComputerName" winrm.cmd quickconfig -transport:https -q
    }
}
