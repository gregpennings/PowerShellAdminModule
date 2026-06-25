Function Find-VMByIPExact {
    <#
    .SYNOPSIS
        Backward-compatible wrapper. Use Get-VMInfo -IPExact instead.

    .DESCRIPTION
        Superseded by Get-VMInfo, which queries VMware and Nutanix and returns
        a single normalized object set. This wrapper is kept so existing scripts
        and habits that call Find-VMByIPExact keep working.

    .PARAMETER IP
        Exact guest IP address to match.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$IP
    )
    Get-VMInfo -IPExact $IP
}
