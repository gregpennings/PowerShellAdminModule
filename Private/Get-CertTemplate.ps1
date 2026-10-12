function Get-CertTemplate {
    <#
    .SYNOPSIS
        Returns the AD CS certificate template a certificate was issued from,
        or $null if it carries no template extension.

    .DESCRIPTION
        Only certificates issued by a Microsoft enterprise CA (AD CS) record
        their template; public CAs don't, so $null is the normal result for
        those. Two extensions are checked:

          1.3.6.1.4.1.311.21.7  Certificate Template Information (v2+
                                templates): SEQUENCE { templateID OID,
                                majorVersion INTEGER, minorVersion INTEGER
                                OPTIONAL }. The OID is resolved to the
                                template's display name through Windows'
                                OID lookup, which consults AD on a
                                domain-joined machine; off-domain (or for
                                another forest's CA) Name falls back to the
                                OID itself.
          1.3.6.1.4.1.311.20.2  Certificate Template Name (v1 templates such
                                as WebServer or Machine): the template's
                                short name as a BMPString. No OID or version.

        The ASN.1 is decoded directly rather than parsing X509Extension.Format
        text, because Format's "Template=" labels are localized.

    .PARAMETER Extensions
        The Extensions of an X509Certificate2.

    .OUTPUTS
        PSCustomObject (Name, Oid, MajorVersion, MinorVersion), or $null.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [AllowNull()]
        [AllowEmptyCollection()]
        $Extensions
    )

    $v2 = $Extensions | Where-Object { $_.Oid.Value -eq '1.3.6.1.4.1.311.21.7' } | Select-Object -First 1
    $v1 = $Extensions | Where-Object { $_.Oid.Value -eq '1.3.6.1.4.1.311.20.2' } | Select-Object -First 1
    if (-not ($v2 -or $v1)) { return $null }

    # AsnReader ships in-box from .NET 5 (PowerShell 7.1); the module still
    # loads on 7.0, where the template is skipped rather than failing the
    # whole certificate lookup.
    if (-not ('System.Formats.Asn1.AsnReader' -as [type])) {
        Write-Verbose "Certificate has a template extension, but decoding it requires PowerShell 7.1+ (System.Formats.Asn1). Current version: $($PSVersionTable.PSVersion)"
        return $null
    }
    $der = [System.Formats.Asn1.AsnEncodingRules]::DER

    try {
        if ($v2) {
            $sequence = [System.Formats.Asn1.AsnReader]::new($v2.RawData, $der).ReadSequence()
            $oid = $sequence.ReadObjectIdentifier()
            $major = [int]$sequence.ReadInteger()
            $minor = if ($sequence.HasData) { [int]$sequence.ReadInteger() } else { $null }
            # Oid's constructor leaves FriendlyName empty when the lookup
            # misses (Oid.FromOidValue throws instead).
            $friendlyName = [System.Security.Cryptography.Oid]::new($oid).FriendlyName
            return [PSCustomObject]@{
                Name         = if ($friendlyName) { $friendlyName } else { $oid }
                Oid          = $oid
                MajorVersion = $major
                MinorVersion = $minor
            }
        }

        $reader = [System.Formats.Asn1.AsnReader]::new($v1.RawData, $der)
        [PSCustomObject]@{
            Name         = $reader.ReadCharacterString([System.Formats.Asn1.UniversalTagNumber]::BMPString)
            Oid          = $null
            MajorVersion = $null
            MinorVersion = $null
        }
    } catch {
        # A malformed template extension shouldn't sink the rest of the
        # certificate's details.
        Write-Warning "Could not decode the certificate template extension: $($_.Exception.GetBaseException().Message)"
        $null
    }
}
