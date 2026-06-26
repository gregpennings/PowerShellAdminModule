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

    .EXAMPLE
        Find-VMByIPExact 10.1.2.34
        Finds the VM whose guest IP is exactly 10.1.2.34.
        Wrapper for Get-VMInfo -IPExact.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$IP
    )
    Get-VMInfo -IPExact $IP
}
