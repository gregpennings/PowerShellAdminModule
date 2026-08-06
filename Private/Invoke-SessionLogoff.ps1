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
        Invoke-RDUserLogoff -HostServer $ComputerName -UnifiedSessionID $SessionID -Force
    }
}
