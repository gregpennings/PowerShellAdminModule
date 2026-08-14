---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Get-Profile
---

# Get-Profile

## SYNOPSIS

Lists non-loaded, non-special user profiles on a computer.

## SYNTAX

### __AllParameterSets

```
Get-Profile [[-ComputerName] <string>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Queries Win32_UserProfile via a CIM session for profiles that are not
currently loaded and are not special/system profiles -- i.e.
the user
profiles that are candidates for cleanup.
Omit -ComputerName to query
the local computer.

## EXAMPLES

### EXAMPLE 1

Get-Profile -ComputerName SERVER01

### EXAMPLE 2

Get-Profile -ComputerName SERVER01 | Where-Object { $_.LastUseTime -lt (Get-Date).AddDays(-90) } | Remove-Profile
Filters to profiles unused for 90+ days, then removes just those.

## PARAMETERS

### -ComputerName

The computer to query.
Defaults to the local computer.

```yaml
Type: System.String
DefaultValue: $env:COMPUTERNAME
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: false
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

### CIM Win32_UserProfile instances. Pipe them to Remove-Profile to remove
exactly the profiles selected here.

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/Get-Profile.html)
