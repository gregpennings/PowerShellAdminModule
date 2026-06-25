function Enable-RemoteDesktop {
    <#
    .SYNOPSIS
        Enables Remote Desktop (RDP) on a computer.

    .DESCRIPTION
        Ensures WinRM is available (enabling it via PsExec if the WinRM port is not
        already open), then enables Remote Desktop on the target by clearing
        fDenyTSConnections and enabling the 'Remote Desktop' firewall rule group
        over a PowerShell session.

    .PARAMETER ComputerName
        The target computer. Defaults to the local computer.

    .PARAMETER PsExecPath
        Path to PsExec, used only if WinRM must be enabled first. Defaults to the
        configured PsExecPath (Get-AdminConfig / Set-AdminConfig).

    .EXAMPLE
        Enable-RemoteDesktop -ComputerName SERVER01
        Enables RDP on SERVER01 and reports the resulting RDP port test.

    .OUTPUTS
        The final Test-NetConnection RDP port-test result, when changes are made.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [string]$PsExecPath   = $script:AdminConfig.PsExecPath
    )

    if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
        Write-Warning "$ComputerName did not respond to ping. You may need to adjust the firewall."
    }

    # RDP is configured over a PS session below, so make sure WinRM is up first
    if (-not (Test-NetConnection -ComputerName $ComputerName -CommonTCPPort WINRM).TcpTestSucceeded) {
        if ($PSCmdlet.ShouldProcess($ComputerName, "Enable WinRM via PsExec")) {
            & $PsExecPath -s "\\$ComputerName" winrm.cmd quickconfig -q
        }
    }

    if ((Test-NetConnection -ComputerName $ComputerName -CommonTCPPort RDP).TcpTestSucceeded) {
        Write-Host "RDP is already enabled on $ComputerName."
        return
    }

    if ($PSCmdlet.ShouldProcess($ComputerName, "Enable Remote Desktop")) {
        $session = New-PSSession -ComputerName $ComputerName
        try {
            Invoke-Command -Session $session -ScriptBlock {
                Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0
                Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'
            }
        } finally {
            Remove-PSSession $session
        }
        Test-NetConnection -ComputerName $ComputerName -CommonTCPPort RDP
    }
}
