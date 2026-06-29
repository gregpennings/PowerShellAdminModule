Function Get-HyperVHostFromAD {
    <#
    .SYNOPSIS
        Discovers Hyper-V hosts from Active Directory and returns their DNS host names.

    .DESCRIPTION
        Every Hyper-V host publishes a service connection point (SCP) named
        "Microsoft Hyper-V" under its own computer object in AD. This function finds
        those SCPs and resolves each one to its parent computer's DNS host name, so
        you get the full set of Hyper-V hosts without maintaining a static list.

        This catches standalone hosts and every node of a failover cluster (each node
        publishes its own SCP). Filtering computers by operating system would NOT
        work -- a Windows Server with the Hyper-V role reports an ordinary Server OS.

        Pipe the result straight into Connect-HyperVHost, or just use
        'Connect-HyperVHost -FromAD', which calls this for you.

    .PARAMETER Server
        Domain or domain controller to query. Omit to use the current domain. Use
        this when the Hyper-V hosts live in a different domain/forest than your
        account (e.g. -Server hci.pvt).

    .PARAMETER SearchBase
        Limit the SCP search to a specific OU/container distinguished name. Omit to
        search the whole domain.

    .PARAMETER Credential
        Credential for the AD query, if the current identity can't read the target
        domain.

    .OUTPUTS
        System.String -- one DNS host name per discovered Hyper-V host, sorted unique.

    .EXAMPLE
        Get-HyperVHostFromAD
        Lists every Hyper-V host registered in the current domain.

    .EXAMPLE
        Get-HyperVHostFromAD -Server hci.pvt
        Discovers hosts in the hci.pvt domain (e.g. when your account is elsewhere).

    .EXAMPLE
        Connect-HyperVHost -ComputerName (Get-HyperVHostFromAD -Server hci.pvt)
        Discovers and mounts them in one step (or just: Connect-HyperVHost -FromAD -Server hci.pvt).
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$Server,

        [string]$SearchBase,

        [System.Management.Automation.PSCredential]$Credential
    )

    # Shared AD parameters (Server/Credential apply to both queries below).
    $adParams = @{ ErrorAction = 'Stop' }
    if ($Server)     { $adParams.Server     = $Server }
    if ($Credential) { $adParams.Credential = $Credential }

    # Find the Hyper-V SCPs.
    $scpParams = @{} + $adParams
    $scpParams.LDAPFilter = '(&(objectClass=serviceConnectionPoint)(name=Microsoft Hyper-V))'
    if ($SearchBase) { $scpParams.SearchBase = $SearchBase }

    try {
        $scps = Get-ADObject @scpParams
    } catch {
        throw "Failed to query Active Directory for Hyper-V hosts$(if ($Server) { " on '$Server'" }): $_"
    }

    if (-not $scps) {
        Write-Warning "No 'Microsoft Hyper-V' service connection points found$(if ($Server) { " on '$Server'" })."
        return
    }

    # Resolve each SCP's parent computer object to its DNS host name. The SCP DN is
    # CN=Microsoft Hyper-V,<computer-object-DN>, so strip the leading RDN.
    $scps | ForEach-Object {
        $parentDn = ($_.DistinguishedName -split ',', 2)[1]
        try {
            (Get-ADComputer -Identity $parentDn @adParams).DNSHostName
        } catch {
            Write-Warning "Could not resolve host for SCP '$($_.DistinguishedName)': $_"
        }
    } | Where-Object { $_ } | Sort-Object -Unique
}
