Function Disconnect-HyperVHost {
    <#
    .SYNOPSIS
        Closes Hyper-V CIM sessions opened by Connect-HyperVHost and drops them
        from the module session store.

    .DESCRIPTION
        Removes the underlying CIM session(s) and forgets them. With no
        -ComputerName, disconnects every mounted host. Safe to call for hosts that
        are not connected (they are simply skipped).

    .PARAMETER ComputerName
        One or more host names to disconnect. Omit to disconnect all mounted hosts.

    .EXAMPLE
        Disconnect-HyperVHost
        Closes every mounted Hyper-V session.

    .EXAMPLE
        Disconnect-HyperVHost -ComputerName hv01
        Closes just the session to hv01.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0)]
        [string[]]$ComputerName
    )

    $targets = if ($ComputerName) { $ComputerName } else { @($script:HyperVSessions.Keys) }

    foreach ($name in $targets) {
        $session = $script:HyperVSessions[$name]
        if (-not $session) {
            Write-Verbose "Hyper-V host '$name' is not connected; skipping."
            continue
        }
        if ($PSCmdlet.ShouldProcess($name, 'Disconnect Hyper-V host')) {
            Remove-CimSession -CimSession $session -ErrorAction SilentlyContinue
            $script:HyperVSessions.Remove($name)
            Write-Verbose "Disconnected Hyper-V host '$name'."
        }
    }
}
