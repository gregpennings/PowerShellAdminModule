function Invoke-OnComputer {
    <#
    .SYNOPSIS
        Runs a script block on a computer: in-process if it's this computer,
        otherwise over WinRM (Invoke-Command) against the computer's FQDN.

    .DESCRIPTION
        Shared transport for the session functions (Get-QuserOutput,
        Invoke-SessionLogoff), so quser and logoff always run on the target
        itself instead of reaching it over Terminal Services RPC
        ('quser /server:', 'logoff /server:'), which hosts commonly refuse
        ("Error [1707]: The network address is invalid").

        A short name is resolved to its DNS FQDN before connecting. Hosts
        aren't all in the caller's domain (e.g. a short name can resolve
        into hci.pvt), and the FQDN is what the Kerberos SPN
        (HTTP/host.domain) and cross-domain referral are built on. IP
        addresses are passed through unchanged -- reverse DNS can be stale,
        and a stale PTR would aim this at the wrong machine. Note WinRM
        can't use Kerberos with an IP; it needs NTLM plus TrustedHosts.

    .PARAMETER ComputerName
        The target computer (short name, FQDN, or IP).

    .PARAMETER ScriptBlock
        What to run on the target.

    .PARAMETER ArgumentList
        Arguments passed to the script block's param() block.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [object[]]$ArgumentList = @()
    )

    $isLocal = ($ComputerName -in @('.', 'localhost', '127.0.0.1', '::1', $env:COMPUTERNAME)) -or
        ($ComputerName.Split('.')[0] -eq $env:COMPUTERNAME)
    if ($isLocal) {
        return & $ScriptBlock @ArgumentList
    }

    $target = $ComputerName
    $ip = $null
    if (-not $ComputerName.Contains('.') -and -not [System.Net.IPAddress]::TryParse($ComputerName, [ref]$ip)) {
        try {
            $target = [System.Net.Dns]::GetHostEntry($ComputerName).HostName
            Write-Verbose "Resolved $ComputerName to $target."
        } catch {
            Write-Verbose "Could not resolve $ComputerName to an FQDN ($($_.Exception.Message)); using it as given."
        }
    }

    Invoke-Command -ComputerName $target -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList -ErrorAction Stop
}
