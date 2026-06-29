Function Get-HyperVSession {
    <#
    .SYNOPSIS
        Returns the Hyper-V CIM sessions currently mounted by Connect-HyperVHost.

    .DESCRIPTION
        Read-only view of the module-scoped Hyper-V session store that
        Get-VMInfo / Get-VMInfoAllVMs (Platform HyperV) query. Use it to confirm
        which hosts are connected and the state of each session.

    .OUTPUTS
        Microsoft.Management.Infrastructure.CimSession (one per connected host).

    .EXAMPLE
        Get-HyperVSession
        Lists the connected Hyper-V hosts and their session state.

    .EXAMPLE
        Get-HyperVSession | Select-Object ComputerName, InstanceId
        Projects just the identity of each open session.
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimSession])]
    param()

    $script:HyperVSessions.Values
}
