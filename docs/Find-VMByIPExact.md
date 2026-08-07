---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Find-VMByIPExact
---

# Find-VMByIPExact

## SYNOPSIS

Backward-compatible wrapper. Use Get-VMInfo -IPExact instead.

## SYNTAX

### __AllParameterSets

```
Find-VMByIPExact [-IP] <string>
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Superseded by Get-VMInfo, which queries VMware and Nutanix and returns
a single normalized object set.
This wrapper is kept so existing scripts
and habits that call Find-VMByIPExact keep working.

## EXAMPLES

### EXAMPLE 1

Find-VMByIPExact 10.1.2.34
Finds the VM whose guest IP is exactly 10.1.2.34.
Wrapper for Get-VMInfo -IPExact.

## PARAMETERS

### -IP

Exact guest IP address to match.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: true
  ValueFromPipeline: false
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

## OUTPUTS

## NOTES

## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/Find-VMByIPExact.html)
