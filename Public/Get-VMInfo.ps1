Function Get-VMInfo {
    <#
    .SYNOPSIS
        Lists VM info from VMware vCenter(s), Nutanix Prism Central(s), and
        Hyper-V host(s).

    .DESCRIPTION
        Filters the on-disk VM info cache (see Update-VMInfoCache) by name or
        IP and returns matching VMs, normalized into a single object shape
        across platforms. Cached reads do no network calls, so they're near-
        instant -- the tradeoff is PowerState and everything else can be as
        stale as the cache. Pass -Live to bypass the cache and query every
        connected vCenter, Prism Central, and Hyper-V host directly (slower;
        several per-VM round trips per platform). If no cache exists yet, this
        falls back to a live query automatically, with a warning.

        Assumes connections are already established (see profile: Connect-VIServer
        / Connect-PrismCentral / Connect-HyperVHost) -- required either way, since
        Update-VMInfoCache needs them too when it builds the cache.

        Hyper-V has no ambient connection, so its hosts must be mounted first with
        Connect-HyperVHost (CIM sessions held by the module). Clustered Hyper-V VMs
        are deduped by VM id, so connecting every cluster node never double-counts.

        VMs can be selected by name (default), by exact IP, or by partial IP.

    .PARAMETER VM
        VM name (or substring) to match. Defaults to the local computer name.

    .PARAMETER IPExact
        Return VMs whose guest IP matches this address exactly.

    .PARAMETER IPLike
        Return VMs whose guest IP contains this substring (e.g. a subnet "10.1.2").

    .PARAMETER Platform
        Limit the query to one platform (VMware, Nutanix, or HyperV). Defaults to
        All. 'Both' is accepted as a back-compat synonym for All (it predates
        Hyper-V support, when there were only two platforms).

    .PARAMETER Live
        Bypass the cache and query every platform directly. Use this when you
        actually need current PowerState or you're checking whether a server is
        online right now -- the cache is best-effort for everything else.

    .PARAMETER NoResolveDns
        Only applies to a live query (-Live, or the automatic fallback when no
        cache exists yet). Skip reverse-DNS resolution: by default, rows the
        hypervisor doesn't supply a DnsName for (Nutanix, or VMware without guest
        tools) have their first IP reverse-resolved to its registered network
        name; this adds one DNS lookup per such row, so pass -NoResolveDns on
        large sweeps. Cached reads never do DNS lookups either way -- DnsName is
        whatever was resolved when the cache was built.

    .OUTPUTS
        PSCustomObject with a common set of properties across platforms,
        including a Platform column indicating the source. Default display
        columns: Name, DnsName, IPAddresses, Notes.

    .EXAMPLE
        Get-VMInfo web01

    .EXAMPLE
        Get-VMInfo -IPExact 1.2.3.4

    .EXAMPLE
        Get-VMInfo -IPLike 10.1.2 -Platform Nutanix

    .EXAMPLE
        Connect-HyperVHost -ComputerName hv01,hv02
        Get-VMInfo SERVER01 -Platform HyperV
        Mount the Hyper-V hosts once, then query them like any other platform.

    .EXAMPLE
        Get-VMInfo SERVER01 | Select-Object Name, DnsName, IPAddresses
        Looks up a VM by name and projects just the identity columns.

    .EXAMPLE
        Get-VMInfo web01 -Live
        Skips the cache and checks web01 live -- e.g. to confirm it's actually
        up right now, or to see current PowerState.

    .LINK
    https://gregpennings.github.io/PowerShellAdminModule/Get-VMInfo.html
#>
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(ParameterSetName = 'ByName', Position = 0)]
        [string]$VM = $env:COMPUTERNAME,

        [Parameter(ParameterSetName = 'ByIPExact', Mandatory)]
        [string]$IPExact,

        [Parameter(ParameterSetName = 'ByIPLike', Mandatory)]
        [string]$IPLike,

        # 'Both' retained as a back-compat synonym for 'All' (pre-Hyper-V default).
        [ValidateSet('All', 'Both', 'VMware', 'Nutanix', 'HyperV')][string]$Platform = 'All',

        [switch]$Live,

        [switch]$NoResolveDns
    )

    $mode = $PSCmdlet.ParameterSetName
    $liveArgs = @{
        Mode        = $mode
        VM          = $VM
        IPExact     = $IPExact
        IPLike      = $IPLike
        Platform    = $Platform
        NoResolveDns = $NoResolveDns
    }

    if ($Live) {
        Get-VMInfoLive @liveArgs
        return
    }

    if (-not (Test-Path -LiteralPath $script:VMInfoCachePath)) {
        Write-Warning "No VM info cache found at '$script:VMInfoCachePath'. Querying live (slow) -- run Update-VMInfoCache to build a cache (add it to your profile so this stops happening)."
        Get-VMInfoLive @liveArgs
        return
    }

    try {
        $cache = Import-Clixml -LiteralPath $script:VMInfoCachePath
    } catch {
        Write-Warning "Failed to read VM info cache '$script:VMInfoCachePath' ($_); querying live instead."
        Get-VMInfoLive @liveArgs
        return
    }

    $all = $Platform -in 'All', 'Both'
    if (-not $all -and $cache.Platform -notin 'All', 'Both', $Platform) {
        Write-Warning "Cache was last built with -Platform $($cache.Platform); it may not include $Platform VMs. Run Update-VMInfoCache -Platform $Platform, or pass -Live."
    }

    $maxAge = (Get-AdminConfig).VMInfoCacheMaxAgeMinutes
    $ageMinutes = ((Get-Date) - $cache.Timestamp).TotalMinutes
    if ($maxAge -and $ageMinutes -gt $maxAge) {
        Write-Warning ("VM info cache is from {0:g} ({1:N0} min old, older than the configured {2} min). Run Update-VMInfoCache to refresh, or pass -Live." -f $cache.Timestamp, $ageMinutes, $maxAge)
    }

    $candidates = $cache.VMs
    if (-not $all) { $candidates = $candidates | Where-Object Platform -eq $Platform }

    $filtered = switch ($mode) {
        'ByName'    { $candidates | Where-Object Name -like "*$VM*" }
        'ByIPExact' { $candidates | Where-Object { ($_.IPAddresses -split ',\s*') -contains $IPExact } }
        'ByIPLike'  { $candidates | Where-Object { $_.IPAddresses -like "*$IPLike*" } }
    }

    $filtered | Sort-Object Platform, Name
}
