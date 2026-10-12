function Get-CertKeyInfo {
    <#
    .SYNOPSIS
        Returns the algorithm, size, and SPKI bytes of a certificate or CSR
        public key.

    .DESCRIPTION
        Shared by Get-CertInfo and Get-SSLCertInfo. Spki is the
        SubjectPublicKeyInfo encoding, which Get-CertInfo -Compare uses to
        match a CSR's key against a certificate's.

    .PARAMETER PublicKey
        The PublicKey from an X509Certificate2 or a CertificateRequest.

    .OUTPUTS
        PSCustomObject (Algorithm, KeySize, Spki).
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)]
        [System.Security.Cryptography.X509Certificates.PublicKey]$PublicKey
    )

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
