function Get-CertInfo {
    <#
    .SYNOPSIS
        Displays details from a CSR or PEM certificate file, and can compare a
        CSR against an issued certificate or test a certificate chain.

    .DESCRIPTION
        -Csr alone decodes a PKCS#10 certificate signing request: subject,
        SANs, and public key algorithm/size. (The CSR's own signature
        algorithm isn't exposed by .NET's CSR-loading API and is
        intentionally left out rather than guessed.)

        -Pem alone decodes a PEM-encoded X.509 certificate: subject, issuer,
        validity window, SANs, key info, and signature algorithm.

        -Csr and -Pem together with -Compare check whether the CSR's public
        key matches the certificate's public key -- useful for confirming the
        right CSR was the one that got signed.

        -Pem with -TestCertChain and -ChainPath validates the certificate
        against a supplied intermediate/root bundle, independent of the
        Windows trust store.

        Requires PowerShell 7.1+ (.NET 5, for X509Certificate2.CreateFromPem
        and related PEM-loading APIs) for -Pem and -TestCertChain, and
        PowerShell 7.3+ (.NET 7, for
        CertificateRequest.LoadSigningRequestPem) for -Csr.

    .PARAMETER Csr
        Path to a PEM-encoded PKCS#10 certificate signing request (.csr).

    .PARAMETER Pem
        Path to a PEM-encoded X.509 certificate (.pem/.crt/.cer).

    .PARAMETER Compare
        Requires both -Csr and -Pem. Reports whether their public keys match.

    .PARAMETER TestCertChain
        Requires -Pem and -ChainPath. Validates the certificate against the
        bundle instead of the OS trust store.

    .PARAMETER ChainPath
        Path to a PEM bundle containing every intermediate and root
        certificate needed to build the chain for -TestCertChain.

    .EXAMPLE
        Get-CertInfo -Csr .\request.csr

    .EXAMPLE
        Get-CertInfo -Pem .\cert.pem

    .EXAMPLE
        Get-CertInfo -Csr .\request.csr -Pem .\cert.pem -Compare

    .EXAMPLE
        Get-CertInfo -Pem .\cert.pem -TestCertChain -ChainPath .\bundle.pem

    .LINK
    https://gregpennings.github.io/PowerShellAdminModule/Get-CertInfo.html
#>
    [CmdletBinding(DefaultParameterSetName = 'Pem')]
    param(
        [Parameter(ParameterSetName = 'Csr', Mandatory)]
        [Parameter(ParameterSetName = 'Compare', Mandatory)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf }, ErrorMessage = "File not found: {0}")]
        [string]$Csr,

        [Parameter(ParameterSetName = 'Pem', Mandatory)]
        [Parameter(ParameterSetName = 'Compare', Mandatory)]
        [Parameter(ParameterSetName = 'Chain', Mandatory)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf }, ErrorMessage = "File not found: {0}")]
        [string]$Pem,

        [Parameter(ParameterSetName = 'Compare', Mandatory)]
        [switch]$Compare,

        [Parameter(ParameterSetName = 'Chain', Mandatory)]
        [switch]$TestCertChain,

        [Parameter(ParameterSetName = 'Chain', Mandatory)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf }, ErrorMessage = "File not found: {0}")]
        [string]$ChainPath
    )

    function Get-KeyInfo([System.Security.Cryptography.X509Certificates.PublicKey]$PublicKey) {
        $rsa = $PublicKey.GetRSAPublicKey()
        if ($rsa) {
            return [PSCustomObject]@{ Algorithm = 'RSA'; KeySize = $rsa.KeySize; Spki = $rsa.ExportSubjectPublicKeyInfo() }
        }
        $ec = $PublicKey.GetECDsaPublicKey()
        if ($ec) {
            return [PSCustomObject]@{ Algorithm = 'ECDSA'; KeySize = $ec.KeySize; Spki = $ec.ExportSubjectPublicKeyInfo() }
        }
        # Unsupported key type (e.g. DSA, Ed25519): report what we can, but
        # RawData isn't SPKI-encoded, so -Compare treats this as "unknown"
        # rather than risk a false non-match.
        return [PSCustomObject]@{ Algorithm = $PublicKey.Oid.FriendlyName; KeySize = $null; Spki = $PublicKey.EncodedKeyValue.RawData }
    }

    function Get-SanText($Extensions) {
        $sanExt = $Extensions | Where-Object { $_.Oid.Value -eq '2.5.29.17' } | Select-Object -First 1
        if ($sanExt) { $sanExt.Format($false) } else { $null }
    }

    function Get-CsrRequest([string]$Path) {
        if ($PSVersionTable.PSVersion -lt [version]'7.3') {
            throw "Reading a CSR requires PowerShell 7.3+ (.NET 7, for CertificateRequest.LoadSigningRequestPem). Current version: $($PSVersionTable.PSVersion)"
        }
        $pemText = Get-Content -Path $Path -Raw
        [System.Security.Cryptography.X509Certificates.CertificateRequest]::LoadSigningRequestPem(
            $pemText,
            [System.Security.Cryptography.HashAlgorithmName]::SHA256,
            [System.Security.Cryptography.X509Certificates.CertificateRequestLoadOptions]::UnsafeLoadCertificateExtensions
        )
    }

    function Get-PemCert([string]$Path) {
        if ($PSVersionTable.PSVersion -lt [version]'7.1') {
            throw "Reading a PEM certificate requires PowerShell 7.1+ (.NET 5, for X509Certificate2.CreateFromPem). Current version: $($PSVersionTable.PSVersion)"
        }
        # CreateFromPem's single-argument overload loads cert-only, with no
        # attempt to pair it to a private key (CreateFromPemFile always tries
        # to load one, and throws if the file doesn't carry a matching key).
        $certText = Get-Content -Path $Path -Raw
        [System.Security.Cryptography.X509Certificates.X509Certificate2]::CreateFromPem($certText)
    }

    try {
        switch ($PSCmdlet.ParameterSetName) {

            'Csr' {
                $request = Get-CsrRequest -Path $Csr
                $keyInfo = Get-KeyInfo -PublicKey $request.PublicKey
                [PSCustomObject]@{
                    PSTypeName      = 'Admin.CertInfo.Csr'
                    Path            = (Resolve-Path $Csr).Path
                    Subject         = $request.SubjectName.Name
                    SubjectAltNames = Get-SanText -Extensions $request.CertificateExtensions
                    KeyAlgorithm    = $keyInfo.Algorithm
                    KeySize         = $keyInfo.KeySize
                }
            }

            'Pem' {
                $cert = Get-PemCert -Path $Pem
                $keyInfo = Get-KeyInfo -PublicKey $cert.PublicKey
                [PSCustomObject]@{
                    PSTypeName          = 'Admin.CertInfo.Cert'
                    Path                = (Resolve-Path $Pem).Path
                    Subject             = $cert.Subject
                    Issuer              = $cert.Issuer
                    Thumbprint          = $cert.Thumbprint
                    SerialNumber        = $cert.SerialNumber
                    NotBefore           = $cert.NotBefore
                    NotAfter            = $cert.NotAfter
                    DaysUntilExpiration = [math]::Round(($cert.NotAfter - (Get-Date)).TotalDays)
                    SubjectAltNames     = Get-SanText -Extensions $cert.Extensions
                    KeyAlgorithm        = $keyInfo.Algorithm
                    KeySize             = $keyInfo.KeySize
                    SignatureAlgorithm  = $cert.SignatureAlgorithm.FriendlyName
                }
            }

            'Compare' {
                $request = Get-CsrRequest -Path $Csr
                $cert = Get-PemCert -Path $Pem
                $csrKey = Get-KeyInfo -PublicKey $request.PublicKey
                $certKey = Get-KeyInfo -PublicKey $cert.PublicKey
                $match = if ($null -eq $csrKey.KeySize -or $null -eq $certKey.KeySize) {
                    $null
                } else {
                    [Convert]::ToBase64String($csrKey.Spki) -eq [Convert]::ToBase64String($certKey.Spki)
                }
                [PSCustomObject]@{
                    PSTypeName       = 'Admin.CertInfo.Compare'
                    CsrPath          = (Resolve-Path $Csr).Path
                    CertPath         = (Resolve-Path $Pem).Path
                    CsrSubject       = $request.SubjectName.Name
                    CertSubject      = $cert.Subject
                    CsrKeyAlgorithm  = $csrKey.Algorithm
                    CsrKeySize       = $csrKey.KeySize
                    CertKeyAlgorithm = $certKey.Algorithm
                    CertKeySize      = $certKey.KeySize
                    PublicKeyMatch   = $match
                }
            }

            'Chain' {
                if ($PSVersionTable.PSVersion -lt [version]'7.1') {
                    throw "Chain validation requires PowerShell 7.1+ (.NET 5, for X509Certificate2Collection.ImportFromPemFile / X509ChainTrustMode.CustomRootTrust). Current version: $($PSVersionTable.PSVersion)"
                }
                $cert = Get-PemCert -Path $Pem
                $bundle = [System.Security.Cryptography.X509Certificates.X509Certificate2Collection]::new()
                $bundle.ImportFromPemFile($ChainPath)

                $chain = [System.Security.Cryptography.X509Certificates.X509Chain]::new()
                $chain.ChainPolicy.TrustMode = [System.Security.Cryptography.X509Certificates.X509ChainTrustMode]::CustomRootTrust
                $chain.ChainPolicy.CustomTrustStore.AddRange($bundle)
                $chain.ChainPolicy.RevocationMode = [System.Security.Cryptography.X509Certificates.X509RevocationMode]::NoCheck

                $isValid = $chain.Build($cert)
                $statusText = ($chain.ChainStatus | ForEach-Object { "$($_.Status): $($_.StatusInformation.Trim())" }) -join '; '

                [PSCustomObject]@{
                    PSTypeName  = 'Admin.CertInfo.Chain'
                    CertPath    = (Resolve-Path $Pem).Path
                    ChainPath   = (Resolve-Path $ChainPath).Path
                    Subject     = $cert.Subject
                    ChainValid  = $isValid
                    ChainStatus = if ($statusText) { $statusText } else { 'No errors' }
                }
            }
        }
    } catch {
        Write-Error "Get-CertInfo failed: $_"
    }
}
