function Enable-WinRM {
    <#
    .SYNOPSIS
        Enables PowerShell Remoting (WinRM) on a computer using PsExec.

    .DESCRIPTION
        Checks whether WinRM/WSMan already responds on the target. If not, runs
        'winrm.cmd quickconfig' remotely via PsExec (under the SYSTEM account) to
        enable it. Requires PsExec (see Get-AdminConfig / Set-AdminConfig PsExecPath)
        and SMB/RPC reachability to the target.

    .PARAMETER ComputerName
        The target computer. Defaults to the local computer.

    .PARAMETER PsExecPath
        Path to the PsExec executable. Defaults to the configured PsExecPath.

    .EXAMPLE
        Enable-WinRM -ComputerName SERVER01
        Enables WinRM on SERVER01 if it is not already configured.

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
    }

    if (Test-WSMan -ComputerName $ComputerName -ErrorAction SilentlyContinue) {
        Write-Host "WinRM is already enabled on $ComputerName."
        return
    }

    if ($PSCmdlet.ShouldProcess($ComputerName, "Enable WinRM via PsExec")) {
        & $PsExecPath -s "\\$ComputerName" winrm.cmd quickconfig -q
    }
}
