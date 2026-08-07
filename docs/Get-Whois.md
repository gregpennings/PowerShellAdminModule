---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Get-Whois
---

# Get-Whois

## SYNOPSIS

Performs an RDAP (modern WHOIS) lookup for a domain.

## SYNTAX

### __AllParameterSets

```
Get-Whois [-Domain] <string>
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Resolves the domain's TLD to its RDAP service via the IANA bootstrap registry,
queries that RDAP server, and returns a summary with the domain status,
registrar, name servers, key events (registration/expiry), and DNSSEC
delegation.
RDAP is the JSON successor to legacy WHOIS.

## EXAMPLES

### EXAMPLE 1

Get-Whois example.com

### EXAMPLE 2

'example.com','example.org' | Get-Whois

### EXAMPLE 3

whois example.com
The module defines a 'whois' alias for Get-Whois.

## PARAMETERS

### -Domain

The domain to look up (e.g.
example.com).
Accepts pipeline input.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
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

### PSCustomObject (Domain

{{ Fill in the Description }}

## NOTES

Requires outbound HTTPS to data.iana.org and the relevant RDAP server.


## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/Get-Whois.html)
