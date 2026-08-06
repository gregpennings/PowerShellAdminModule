function Invoke-SessionLogoff {
    <#
    .SYNOPSIS
        Logs off a single quser session on a remote computer.

    .DESCRIPTION
        Shared logoff dispatch used by both of Clear-LoggedOnSessions'
        parameter sets (-ComputerName loop and pipeline). Handles RDP-named
        sessions (rdp-tcp#NN, via 'logoff' on the host) and numeric session
        IDs (via Invoke-RDUserLogoff).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [Parameter(Mandatory = $true)]
        [string]$SessionID
    )

    if ($SessionID -match 'rdp-tcp#\d+') {
        $sessionName = $SessionID
        Invoke-Command -ComputerName $ComputerName -ScriptBlock { logoff $using:sessionName }
    } else {
        # -Confirm:$false: the caller already confirmed via ShouldProcess above this
        # call. Without it, -Confirm on Clear-LoggedOnSessions bleeds into the
        # RemoteDesktop module's own internal ShouldProcess calls (it builds/tears
        # down an implicit CIM proxy module under %TEMP% on first use), prompting
        # for unrelated "Copy File"/"Remove Directory" operations on that scratch
        # folder -- easy to mistake for something touching a user's profile.
        Invoke-RDUserLogoff -HostServer $ComputerName -UnifiedSessionID $SessionID -Force -Confirm:$false
    }
}
