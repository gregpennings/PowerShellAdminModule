Function Connect-HyperVHost {
    <#
    .SYNOPSIS
        "Mounts" one or more Hyper-V hosts by opening CIM sessions the VM-info
        functions reuse. The Hyper-V analog of Connect-VIServer / Connect-PrismCentral.

    .DESCRIPTION
        Hyper-V has no central management point and no ambient connection: every
        Hyper-V cmdlet reaches a host explicitly. This function opens a CIM session
        to each host and stores it module-scoped, keyed by computer name, so
        Get-VMInfo / Get-VMInfoAllVMs (Platform HyperV) can query them without
        re-connecting each call.

        Call this once at startup -- e.g. from your PowerShell profile, right where
        you Connect-VIServer / Connect-PrismCentral -- to keep the sessions warm for
        the session's lifetime. Re-running it for a host that is already connected
        replaces the old session (so it is safe to call again after a host reboots).

        Three ways to supply the host list:
          -ComputerName    explicit names (default: the configured HyperVHosts)
          -FromAD          discover every Hyper-V host from Active Directory
          (config)         with no -ComputerName, falls back to
                           (Get-AdminConfig).HyperVHosts -- set it once with
                           Set-AdminConfig -Name HyperVHosts -Value @('host1','host2').

        -FromAD is the zero-maintenance option: it queries the "Microsoft Hyper-V"
        service connection points each host publishes (see Get-HyperVHostFromAD), so
        new hosts appear automatically. Use -Server for a different domain/forest.

        Authentication uses your current identity by default; pass -Credential for
        workgroup hosts or a separate admin account.

        Standalone and clustered hosts are both fine: connect to each standalone host
        and to every node of each failover cluster. A clustered VM is returned by
        whichever node currently owns it, and Get-VMInfo dedupes by VM id, so listing
        all nodes never double-counts.

    .PARAMETER ComputerName
        One or more Hyper-V host names to connect. Defaults to the configured
        HyperVHosts list (Get-AdminConfig).HyperVHosts.

    .PARAMETER FromAD
        Discover the host list from Active Directory (via Get-HyperVHostFromAD)
        instead of -ComputerName/config. Mounts every Hyper-V host AD knows about.

    .PARAMETER Server
        With -FromAD, the domain or DC to query for hosts (e.g. hci.pvt). Omit to
        use the current domain. Ignored without -FromAD.

    .PARAMETER SearchBase
        With -FromAD, limit AD discovery to a specific OU/container DN. Ignored
        without -FromAD.

    .PARAMETER Credential
        Optional credential for hosts that do not accept your current identity
        (workgroup, different domain, or a dedicated admin account). With -FromAD it
        is also used for the AD discovery query.

    .PARAMETER PassThru
        Return the CIM session objects that were opened (or already open). By default
        the function is quiet and stores the sessions without emitting them.

    .OUTPUTS
        None by default; Microsoft.Management.Infrastructure.CimSession with -PassThru.

    .EXAMPLE
        Connect-HyperVHost -ComputerName hv01,hv02
        Opens CIM sessions to two standalone hosts using the current identity.

    .EXAMPLE
        Connect-HyperVHost -FromAD
        Discovers every Hyper-V host in the current domain and mounts them all.

    .EXAMPLE
        Connect-HyperVHost -FromAD -Server hci.pvt
        Same, but discovers from the hci.pvt domain (use this in your profile).

    .EXAMPLE
        Set-AdminConfig -Name HyperVHosts -Value @('hv01','hv02','clusternodeA','clusternodeB')
        Connect-HyperVHost
        Persists the host list once, then connects them all from config (e.g. in your profile).

    .EXAMPLE
        Connect-HyperVHost -ComputerName wrkgrp-hv01 -Credential (Get-Credential)
        Connects a workgroup host with an explicit credential.

    .EXAMPLE
        Get-VMInfo SERVER01 -Platform HyperV
        After connecting, query Hyper-V like any other platform.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    [OutputType([Microsoft.Management.Infrastructure.CimSession])]
    param(
        [Parameter(ParameterSetName = 'ByName', Position = 0)]
        [string[]]$ComputerName = $script:AdminConfig.HyperVHosts,

        [Parameter(ParameterSetName = 'FromAD', Mandatory)]
        [switch]$FromAD,

        [Parameter(ParameterSetName = 'FromAD')]
        [string]$Server,

        [Parameter(ParameterSetName = 'FromAD')]
        [string]$SearchBase,

        [System.Management.Automation.PSCredential]$Credential,

        [switch]$PassThru
    )

    # Resolve the host list from AD when -FromAD; otherwise use -ComputerName/config.
    if ($FromAD) {
        $discParams = @{}
        if ($Server)     { $discParams.Server     = $Server }
        if ($SearchBase) { $discParams.SearchBase = $SearchBase }
        if ($Credential) { $discParams.Credential = $Credential }
        Write-Verbose "Discovering Hyper-V hosts from Active Directory$(if ($Server) { " ($Server)" })..."
        $ComputerName = Get-HyperVHostFromAD @discParams
    }

    if (-not $ComputerName) {
        Write-Warning "No Hyper-V hosts to connect. Pass -ComputerName, use -FromAD, or set them once with: Set-AdminConfig -Name HyperVHosts -Value @('host1','host2')."
        return
    }

    $opened = foreach ($name in $ComputerName) {
        # Replace any existing session for this host (handles reconnect after reboot).
        $existing = $script:HyperVSessions[$name]
        if ($existing) {
            Remove-CimSession -CimSession $existing -ErrorAction SilentlyContinue
            $script:HyperVSessions.Remove($name)
        }

        try {
            $params = @{ ComputerName = $name; ErrorAction = 'Stop' }
            if ($Credential) { $params.Credential = $Credential }
            $session = New-CimSession @params
            $script:HyperVSessions[$name] = $session
            Write-Verbose "Connected Hyper-V host '$name'."
            $session
        } catch {
            Write-Warning "Failed to connect Hyper-V host '$name': $_"
        }
    }

    if ($PassThru) { $opened }
}
