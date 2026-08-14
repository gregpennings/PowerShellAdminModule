function Invoke-SessionLogoff {
    <#
    .SYNOPSIS
        Logs off a single quser session on a remote computer.

    .DESCRIPTION
        Shared logoff dispatch used by both of Clear-LoggedOnSession's
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

    # The caller already confirmed via its own ShouldProcess before calling this.
    # Without suppressing it here, -Confirm on Clear-LoggedOnSession bleeds via
    # $ConfirmPreference into whatever ShouldProcess-aware cmdlets run underneath --
    # e.g. the RemoteDesktop module builds/tears down an implicit CIM proxy module
    # under %TEMP% on first use, and its own internal Copy-Item/Remove-Item calls
    # inherit that ambient preference, prompting for unrelated "Copy File"/"Remove
    # Directory" operations on that scratch folder. Invoke-RDUserLogoff itself
    # doesn't declare -Confirm/-WhatIf, so this has to be the preference variable,
    # not a parameter.
    $ConfirmPreference = 'None'

    if ($SessionID -match 'rdp-tcp#\d+') {
        $sessionName = $SessionID
        Invoke-Command -ComputerName $ComputerName -ScriptBlock { logoff $using:sessionName }
    } else {
        Invoke-RDUserLogoff -HostServer $ComputerName -UnifiedSessionID $SessionID -Force
    }
}
