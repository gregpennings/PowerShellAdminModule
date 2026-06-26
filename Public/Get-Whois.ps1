function Get-Whois {
    <#
    .SYNOPSIS
        Performs an RDAP (modern WHOIS) lookup for a domain.

    .DESCRIPTION
        Resolves the domain's TLD to its RDAP service via the IANA bootstrap registry,
        queries that RDAP server, and returns a summary with the domain status,
        registrar, name servers, key events (registration/expiry), and DNSSEC
        delegation. RDAP is the JSON successor to legacy WHOIS.

    .PARAMETER Domain
        The domain to look up (e.g. example.com). Accepts pipeline input.

    .EXAMPLE
        Get-Whois example.com

    .EXAMPLE
        'example.com','example.org' | Get-Whois

    .EXAMPLE
        whois example.com
        The module defines a 'whois' alias for Get-Whois.

    .OUTPUTS
        PSCustomObject (Domain, Status, Registrar, NameServers, Events, DNSSEC).

    .NOTES
        Requires outbound HTTPS to data.iana.org and the relevant RDAP server.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory, ValueFromPipeline)][string]$Domain)
    process {
        $tld = $Domain.Split('.')[-1]
        $services = (Invoke-RestMethod "https://data.iana.org/rdap/dns.json").services
        $rdapRoot = $services | Where-Object { $PSItem[0] -contains $tld } | Select-Object -First 1
        if (-not $rdapRoot) { throw "No RDAP server found for .$tld" }
        $r = Invoke-RestMethod "$($rdapRoot[1][0])domain/$Domain"

        $registrar = $r.entities | Where-Object { $PSItem.roles -contains 'registrar' } |
            Select-Object -First 1 -ExpandProperty vcardArray |
            Select-Object -Last 1 |
            ForEach-Object { $PSItem | Where-Object { $PSItem[0] -eq 'fn' } | ForEach-Object { $PSItem[3] } }

        $events = $r.events | Where-Object { $PSItem.eventAction -ne 'last update of RDAP database' } |
            ForEach-Object { "  $($PSItem.eventAction): $([datetime]$PSItem.eventDate | Get-Date -Format 'yyyy-MM-dd')" }

        $nameservers = $r.nameservers | ForEach-Object { "  $($PSItem.ldhName)" }

        [PSCustomObject]@{
            Domain      = $r.ldhName
            Status      = $r.status -join ', '
            Registrar   = $registrar
            NameServers = $nameservers -join "`n"
            Events      = $events -join "`n"
            DNSSEC      = $r.secureDNS.delegationSigned
        }
    }
}
Set-Alias -Name whois -Value Get-Whois
