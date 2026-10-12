function Get-CertSanText {
    <#
    .SYNOPSIS
        Returns the Subject Alternative Name extension of a certificate or CSR
        as display text, or $null if there isn't one.

    .PARAMETER Extensions
        The Extensions of an X509Certificate2, or the CertificateExtensions of
        a CertificateRequest.

    .OUTPUTS
        System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [AllowNull()]
        [AllowEmptyCollection()]
        $Extensions
    )

    $sanExt = $Extensions | Where-Object { $_.Oid.Value -eq '2.5.29.17' } | Select-Object -First 1
    if ($sanExt) { $sanExt.Format($false) } else { $null }
}
