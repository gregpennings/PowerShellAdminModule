Function Find-VMByIPLike {
    <#
    .SYNOPSIS
        Backward-compatible wrapper. Use Get-VMInfo -IPLike instead.

    .DESCRIPTION
        Superseded by Get-VMInfo, which queries VMware and Nutanix and returns
        a single normalized object set. This wrapper is kept so existing scripts
        and habits that call Find-VMByIPLike keep working.

    .PARAMETER IP
        Partial guest IP to match (e.g. a subnet "10.1.2").

    .EXAMPLE
        Find-VMByIPLike 10.1.2
        Finds VMs whose guest IP contains "10.1.2" (e.g. an entire subnet).
        Shorten the fragment (10.1.2 -> 10.1) to widen the match.
        Wrapper for Get-VMInfo -IPLike.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$IP
    )
    Get-VMInfo -IPLike $IP
}
