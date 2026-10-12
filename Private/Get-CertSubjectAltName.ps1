function Get-CertSubjectAltName {
    <#
    .SYNOPSIS
        Returns the Subject Alternative Names of a certificate or CSR as plain
        values, or 'No SAN applied' if there aren't any.

    .DESCRIPTION
        Shared by Get-CertInfo and Get-SSLCertInfo. Each name is returned
        bare -- www.example.com, not "DNS Name=www.example.com" -- so the
        result can be filtered directly (-contains, -like, Where-Object).

        The extension's GeneralNames are decoded from ASN.1 rather than by
        splitting X509Extension.Format text, because Format's "DNS Name="
        style labels are localized. Handled name types: DNS name, IP address,
        email (rfc822Name), URI, directory name, and UPN (the Microsoft
        otherName). Any other type is skipped with a verbose message.

        On PowerShell 7.0 (no System.Formats.Asn1) it falls back to Format
        text with the labels stripped.

    .PARAMETER Extensions
        The Extensions of an X509Certificate2, or the CertificateExtensions of
        a CertificateRequest.

    .OUTPUTS
        System.String[], or the string 'No SAN applied'.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [AllowNull()]
        [AllowEmptyCollection()]
        $Extensions
    )

    $noSan = 'No SAN applied'
    $sanExt = $Extensions | Where-Object { $_.Oid.Value -eq '2.5.29.17' } | Select-Object -First 1
    if (-not $sanExt) { return $noSan }

    if (-not ('System.Formats.Asn1.AsnReader' -as [type])) {
        $names = @($sanExt.Format($false) -split ',\s*' | ForEach-Object { $_ -replace '^[^=:]+[=:]\s*', '' } | Where-Object { $_ })
        if ($names) { return , $names } else { return $noSan }
    }

    $context = [System.Formats.Asn1.TagClass]::ContextSpecific
    $ia5 = [System.Formats.Asn1.UniversalTagNumber]::IA5String
    $upnOid = '1.3.6.1.4.1.311.20.2.3'

    try {
        $generalNames = [System.Formats.Asn1.AsnReader]::new($sanExt.RawData, [System.Formats.Asn1.AsnEncodingRules]::DER).ReadSequence()
        $names = [System.Collections.Generic.List[string]]::new()
        while ($generalNames.HasData) {
            $tag = $generalNames.PeekTag()
            if ($tag.TagClass -ne $context) {
                $null = $generalNames.ReadEncodedValue()
                continue
            }
            switch ($tag.TagValue) {
                # rfc822Name (email), dNSName, URI: IA5String, implicitly tagged
                { $_ -in 1, 2, 6 } {
                    $names.Add($generalNames.ReadCharacterString($ia5, [System.Formats.Asn1.Asn1Tag]::new($context, $_)))
                }
                # iPAddress: 4 or 16 raw bytes
                7 {
                    $bytes = $generalNames.ReadOctetString([System.Formats.Asn1.Asn1Tag]::new($context, 7))
                    $names.Add([System.Net.IPAddress]::new($bytes).ToString())
                }
                # directoryName: an explicitly tagged X.500 Name
                4 {
                    $directoryName = $generalNames.ReadSequence([System.Formats.Asn1.Asn1Tag]::new($context, 4, $true))
                    $names.Add([System.Security.Cryptography.X509Certificates.X500DistinguishedName]::new($directoryName.ReadEncodedValue().ToArray()).Name)
                }
                # otherName: { type-id OID, [0] EXPLICIT value }; only UPN is decoded
                0 {
                    $otherName = $generalNames.ReadSequence([System.Formats.Asn1.Asn1Tag]::new($context, 0, $true))
                    $typeId = $otherName.ReadObjectIdentifier()
                    if ($typeId -eq $upnOid) {
                        $value = $otherName.ReadSequence([System.Formats.Asn1.Asn1Tag]::new($context, 0, $true))
                        $names.Add($value.ReadCharacterString([System.Formats.Asn1.UniversalTagNumber]::UTF8String))
                    } else {
                        Write-Verbose "Skipping SAN otherName of type $typeId"
                    }
                }
                default {
                    Write-Verbose "Skipping SAN entry with unsupported GeneralName tag [$($tag.TagValue)]"
                    $null = $generalNames.ReadEncodedValue()
                }
            }
        }
        if ($names.Count) { return , $names.ToArray() } else { return $noSan }
    } catch {
        # Malformed SAN data shouldn't sink the rest of the certificate's
        # details; fall back to the display text.
        Write-Warning "Could not decode the Subject Alternative Name extension: $($_.Exception.GetBaseException().Message)"
        , @($sanExt.Format($false))
    }
}
