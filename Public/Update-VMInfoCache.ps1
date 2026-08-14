function Update-VMInfoCache {
    <#
    .SYNOPSIS
        Rebuilds the on-disk cache that Get-VMInfo reads from by default.

    .DESCRIPTION
        Runs the full live query -- every connected vCenter, Prism Central, and
        mounted Hyper-V host, including the per-VM tag/snapshot/datastore/disk
        lookups and reverse-DNS resolution (same as Get-VMInfo -Live) -- and
        writes the result plus a timestamp to:

            $env:LOCALAPPDATA\Admin\VMInfoCache.xml

        This is the slow pass. Run it once (a good place is your profile, right
        after Connect-VIServer / Connect-PrismCentral / Connect-HyperVHost) and
        Get-VMInfo's default cached reads become near-instant, in-memory filters
        over the cached collection -- no network calls, no per-VM round trips.

        Assumes connections are already established, same as Get-VMInfo.

    .PARAMETER Platform
        Which platform(s) to include when rebuilding the cache. Defaults to All.
        Narrowing this means Get-VMInfo's cached reads for the excluded
        platform(s) will come back empty until you rebuild with them included.

    .PARAMETER NoResolveDns
        Skip reverse-DNS resolution while rebuilding the cache (see Get-VMInfo).
        Rows the hypervisor didn't supply a DnsName for will have a blank
        DnsName in every cached read until the cache is rebuilt without this
        switch.

    .EXAMPLE
        Update-VMInfoCache
        Rebuilds the cache from every connected platform.

    .EXAMPLE
        Connect-HyperVHost -FromAD
        Update-VMInfoCache
        Typical profile sequence: mount Hyper-V hosts, then warm the cache.

    .LINK
    https://gregpennings.github.io/PowerShellAdminModule/Update-VMInfoCache.html
#>
    [CmdletBinding()]
    param(
        [ValidateSet('All', 'Both', 'VMware', 'Nutanix', 'HyperV')][string]$Platform = 'All',
        [switch]$NoResolveDns
    )

    $vms = @(Get-VMInfoLive -Mode ByName -VM '' -Platform $Platform -NoResolveDns:$NoResolveDns)

    $dir = Split-Path -Parent $script:VMInfoCachePath
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    [PSCustomObject]@{
        Timestamp = Get-Date
        Platform  = $Platform
        VMs       = $vms
    } | Export-Clixml -LiteralPath $script:VMInfoCachePath -Force

    Write-Verbose "Cached $($vms.Count) VM(s) to $script:VMInfoCachePath"
}
