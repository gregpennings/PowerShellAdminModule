function Get-SSLCertInfo {
    <#
    .SYNOPSIS
        Gets the SSL/TLS certificate a host presents, with its expiration date,
        AD CS template, chain trust, and negotiated TLS details.

    .DESCRIPTION
        Opens a TCP connection to the host on the given port and completes a
        TLS handshake. Any certificate is accepted, so expired, self-signed,
        or otherwise untrusted certs can still be inspected; whether the cert
        would have passed validation is reported instead, in NameMatch,
        ChainTrusted, and ChainStatus.

        Template is only populated for certificates issued by a Microsoft
        enterprise CA (AD CS). Public CAs don't record a template, so it is
        empty for those. The template OID is resolved to its display name on
        a domain-joined machine; elsewhere Template shows the OID.

        CertificateChain is the chain built from the certificates the server
        sent plus this machine's certificate stores, leaf first. Revocation is
        not checked.

    .PARAMETER Url
        The host name or IP to connect to. A full URL is also accepted
        (https://host:8443/path); its host is used, and its port too unless
        -Port is given. Accepts pipeline input.

    .PARAMETER Port
        The TCP port to use for the TLS handshake. Defaults to 443.

    .PARAMETER ServerName
        The host name to send as SNI and to check the certificate against,
        when it differs from the address being connected to -- e.g. connecting
        to each node behind a load balancer by IP while asking for the
        public site's certificate. Defaults to the -Url host.

    .PARAMETER TimeoutSeconds
        How long to wait for the TCP connection, and for each read/write
        during the handshake, before giving up. Defaults to 10.

    .EXAMPLE
        Get-SSLCertInfo -Url www.example.com

    .EXAMPLE
        Get-SSLCertInfo -Url ldap01.contoso.com -Port 636

    .EXAMPLE
        Get-SSLCertInfo -Url 10.0.0.21 -ServerName portal.contoso.com

        Connects to one load-balanced node directly and checks the certificate
        it serves for portal.contoso.com.

    .EXAMPLE
        'a.example.com','b.example.com' | Get-SSLCertInfo |
            Sort-Object ExpirationDate |
            Format-Table Host, ExpirationDate, DaysUntilExpiration, Template

    .EXAMPLE
        (Get-SSLCertInfo -Url www.example.com).CertificateChain | Format-Table

    .OUTPUTS
        Admin.SSLCertInfo

    .LINK
    https://gregpennings.github.io/PowerShellAdminModule/Get-SSLCertInfo.html
#>
    [CmdletBinding()]
    [OutputType('Admin.SSLCertInfo')]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Host', 'ComputerName')]
        [string]$Url,

        [Parameter(Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateRange(1, 65535)]
        [int]$Port = 443,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('SNI')]
        [string]$ServerName,

        [ValidateRange(1, 300)]
        [int]$TimeoutSeconds = 10
    )
    process {
        $hostName = $Url
        $effectivePort = $Port
        $uri = $null
        if ([uri]::TryCreate($Url, [UriKind]::Absolute, [ref]$uri) -and $uri.Host) {
            $hostName = $uri.Host
            if (-not $PSBoundParameters.ContainsKey('Port') -and -not $uri.IsDefaultPort) {
                $effectivePort = $uri.Port
            }
        }
        $targetHost = if ($ServerName) { $ServerName } else { $hostName }
        $timeoutMs = $TimeoutSeconds * 1000

        $tcpClient = $null
        $sslStream = $null
        try {
            $tcpClient = [System.Net.Sockets.TcpClient]::new()
            if (-not $tcpClient.ConnectAsync($hostName, $effectivePort).Wait($timeoutMs)) {
                throw "Timed out after $TimeoutSeconds seconds connecting to ${hostName}:$effectivePort."
            }
            $tcpClient.ReceiveTimeout = $timeoutMs
            $tcpClient.SendTimeout = $timeoutMs

            # The callback runs during AuthenticateAsClient, and the chain it
            # is handed isn't guaranteed to outlive it, so copy out what we
            # need there and always accept the certificate.
            $validation = @{ PolicyErrors = $null; ChainStatus = @(); ChainElements = @() }
            $callback = {
                param($sslSender, $certificate, $chain, $sslPolicyErrors)
                $validation.PolicyErrors = $sslPolicyErrors
                if ($chain) {
                    $validation.ChainStatus = @($chain.ChainStatus | ForEach-Object { "$($_.Status): $($_.StatusInformation.Trim())" })
                    $validation.ChainElements = @(foreach ($element in $chain.ChainElements) {
                        $element.Certificate | Select-Object Subject, Issuer, Thumbprint, NotBefore, NotAfter
                    })
                }
                $true
            }.GetNewClosure()

            $sslStream = [System.Net.Security.SslStream]::new($tcpClient.GetStream(), $false, $callback)
            $sslStream.AuthenticateAsClient($targetHost)
            $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($sslStream.RemoteCertificate)

            $keyInfo = Get-CertKeyInfo -PublicKey $cert.PublicKey
            $template = Get-CertTemplate -Extensions $cert.Extensions
            $policyErrors = [System.Net.Security.SslPolicyErrors]$validation.PolicyErrors
            $chainErrors = [System.Net.Security.SslPolicyErrors]::RemoteCertificateChainErrors
            $nameMismatch = [System.Net.Security.SslPolicyErrors]::RemoteCertificateNameMismatch

            # Each chain entry prints as "subject (expires date)" in list
            # output; pipe CertificateChain to Format-Table for the details.
            $certificateChain = foreach ($element in $validation.ChainElements) {
                $element | Add-Member -MemberType ScriptMethod -Name ToString -Force -Value {
                    "$($this.Subject) (expires $($this.NotAfter.ToString('yyyy-MM-dd')))"
                } -PassThru
            }

            # NegotiatedCipherSuite isn't implemented on every platform/.NET
            # version; report what we can rather than fail the lookup.
            $cipherSuite = try { $sslStream.NegotiatedCipherSuite } catch { $null }

            [PSCustomObject]@{
                PSTypeName          = 'Admin.SSLCertInfo'
                Host                = $hostName
                Port                = $effectivePort
                ServerName          = $targetHost
                Subject             = $cert.Subject
                SubjectAltNames     = Get-CertSanText -Extensions $cert.Extensions
                Issuer              = $cert.Issuer
                Template            = $template.Name
                TemplateOid         = $template.Oid
                NotBefore           = $cert.NotBefore
                ExpirationDate      = $cert.NotAfter
                DaysUntilExpiration = [int][math]::Round(($cert.NotAfter - (Get-Date)).TotalDays)
                Thumbprint          = $cert.Thumbprint
                SerialNumber        = $cert.SerialNumber
                KeyAlgorithm        = $keyInfo.Algorithm
                KeySize             = $keyInfo.KeySize
                SignatureAlgorithm  = $cert.SignatureAlgorithm.FriendlyName
                NameMatch           = -not ($policyErrors -band $nameMismatch)
                ChainTrusted        = -not ($policyErrors -band $chainErrors)
                ChainStatus         = if ($validation.ChainStatus) { $validation.ChainStatus -join '; ' } else { 'No errors' }
                CertificateChain    = @($certificateChain)
                Protocol            = $sslStream.SslProtocol
                CipherSuite         = $cipherSuite
            }
        } catch {
            Write-Error "Failed to retrieve SSL certificate for ${hostName}:${effectivePort}: $($_.Exception.GetBaseException().Message)"
        } finally {
            if ($sslStream) { $sslStream.Dispose() }
            if ($tcpClient) { $tcpClient.Dispose() }
        }
    }
}
