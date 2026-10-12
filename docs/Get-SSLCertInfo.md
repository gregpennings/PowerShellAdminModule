---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/Get-SSLCertInfo.html
Locale: en-US
Module Name: Admin
ms.date: 10-12-2026
PlatyPS schema version: 2024-05-01
title: Get-SSLCertInfo
---

# Get-SSLCertInfo

## SYNOPSIS

Gets the SSL/TLS certificate a host presents, with its expiration date,
AD CS template, chain trust, and negotiated TLS details.

## SYNTAX

### __AllParameterSets

```
Get-SSLCertInfo [-Url] <string> [[-Port] <int>] [-ServerName <string>] [-TimeoutSeconds <int>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Opens a TCP connection to the host on the given port and completes a
TLS handshake.
Any certificate is accepted, so expired, self-signed,
or otherwise untrusted certs can still be inspected; whether the cert
would have passed validation is reported instead, in NameMatch,
ChainTrusted, and ChainStatus.

SAN lists the certificate's Subject Alternative Names as plain values
(www.example.com, 10.0.0.5, ...), so it can be filtered with
-contains or -like; it reads 'No SAN applied' if the cert has none.

Template is only populated for certificates issued by a Microsoft
enterprise CA (AD CS).
Public CAs don't record a template, so it is
empty for those.
The template OID is resolved to its display name on
a domain-joined machine; elsewhere Template shows the OID.

CertificateChain is the chain built from the certificates the server
sent plus this machine's certificate stores, leaf first.
Revocation is
not checked.

## EXAMPLES

### EXAMPLE 1

Get-SSLCertInfo -Url www.example.com

### EXAMPLE 2

Get-SSLCertInfo -Url ldap01.contoso.com -Port 636

### EXAMPLE 3

Get-SSLCertInfo -Url 10.0.0.21 -ServerName portal.contoso.com

Connects to one load-balanced node directly and checks the certificate
it serves for portal.contoso.com.

### EXAMPLE 4

'a.example.com','b.example.com' | Get-SSLCertInfo |
    Sort-Object ExpirationDate |
    Format-Table Host, ExpirationDate, DaysUntilExpiration, Template

### EXAMPLE 5

(Get-SSLCertInfo -Url www.example.com).CertificateChain | Format-Table

## PARAMETERS

### -Port

The TCP port to use for the TLS handshake.
Defaults to 443.

```yaml
Type: System.Int32
DefaultValue: 443
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ServerName

The host name to send as SNI and to check the certificate against,
when it differs from the address being connected to -- e.g.
connecting
to each node behind a load balancer by IP while asking for the
public site's certificate.
Defaults to the -Url host.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- SNI
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -TimeoutSeconds

How long to wait for the TCP connection, and for each read/write
during the handshake, before giving up.
Defaults to 10.

```yaml
Type: System.Int32
DefaultValue: 10
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Url

The host name or IP to connect to.
A full URL is also accepted
(https://host:8443/path); its host is used, and its port too unless
-Port is given.
Accepts pipeline input.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- Host
- ComputerName
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

{{ Fill in the Description }}

### System.Int32

{{ Fill in the Description }}

## OUTPUTS

### Admin.SSLCertInfo

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/Get-SSLCertInfo.html)
