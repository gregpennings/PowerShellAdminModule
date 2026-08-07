---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Get-SSLCertificateExpirationDate
---

# Get-SSLCertificateExpirationDate

## SYNOPSIS

Gets the expiration date of a host's SSL/TLS certificate.

## SYNTAX

### __AllParameterSets

```
Get-SSLCertificateExpirationDate [-Url] <string> [[-Port] <int>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Opens a TCP connection to the host on the given port, completes a TLS
handshake (accepting any certificate, so expired or self-signed certs can
still be inspected), and returns the server certificate's NotAfter date.

## EXAMPLES

### EXAMPLE 1

Get-SSLCertificateExpirationDate -Url www.example.com

### EXAMPLE 2

'a.example.com','b.example.com' | Get-SSLCertificateExpirationDate

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
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Url

The host name or IP to connect to.
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

## OUTPUTS

### System.DateTime

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/Get-SSLCertificateExpirationDate.html)
