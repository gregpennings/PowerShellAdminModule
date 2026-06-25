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
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$IP
    )
    Get-VMInfo -IPLike $IP
}
