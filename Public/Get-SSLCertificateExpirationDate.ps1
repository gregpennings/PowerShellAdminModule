function Get-SSLCertificateExpirationDate {
    <#
    .SYNOPSIS
        Gets the expiration date of a host's SSL/TLS certificate.

    .DESCRIPTION
        Opens a TCP connection to the host on the given port, completes a TLS
        handshake (accepting any certificate, so expired or self-signed certs can
        still be inspected), and returns the server certificate's NotAfter date.

    .PARAMETER Url
        The host name or IP to connect to. Accepts pipeline input.

    .PARAMETER Port
        The TCP port to use for the TLS handshake. Defaults to 443.

    .EXAMPLE
        Get-SSLCertificateExpirationDate -Url www.example.com

    .EXAMPLE
        'a.example.com','b.example.com' | Get-SSLCertificateExpirationDate

    .OUTPUTS
        System.DateTime
    #>
    [CmdletBinding()]
    [OutputType([datetime])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Host', 'ComputerName')]
        [string]$Url,

        [int]$Port = 443
    )
    process {
        $tcpClient = $null
        $sslStream = $null
        try {
            $tcpClient = [System.Net.Sockets.TcpClient]::new($Url, $Port)
            $sslStream = [System.Net.Security.SslStream]::new($tcpClient.GetStream(), $false, { $true })
            $sslStream.AuthenticateAsClient($Url)
            $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($sslStream.RemoteCertificate)
            $cert.NotAfter
        } catch {
            Write-Error "Failed to retrieve SSL certificate expiration date for ${Url}: $_"
        } finally {
            if ($sslStream) { $sslStream.Dispose() }
            if ($tcpClient) { $tcpClient.Dispose() }
        }
    }
}
