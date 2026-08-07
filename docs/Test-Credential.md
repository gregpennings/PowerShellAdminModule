---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Test-Credential
---

# Test-Credential

## SYNOPSIS

Validates a PSCredential against the domain, local machine, or an AD LDS instance.

## SYNTAX

### __AllParameterSets

```
Test-Credential [-Credential] <pscredential> [[-Context] <string>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Uses System.DirectoryServices.AccountManagement to validate the supplied
credential.
If the user name is in DOMAIN\user form, the domain part is used
as the context target.

## EXAMPLES

### EXAMPLE 1

Get-Credential | Test-Credential
Prompts for a credential and returns $true/$false for whether it validates.

### EXAMPLE 2

Test-Credential -Credential $cred -Context Machine

## PARAMETERS

### -Context

The validation context: Domain (default), Machine, or ApplicationDirectory.

```yaml
Type: System.String
DefaultValue: Domain
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

### -Credential

The PSCredential to validate (e.g.
from Get-Credential).
Accepts pipeline input.

```yaml
Type: System.Management.Automation.PSCredential
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

### System.Management.Automation.PSCredential

{{ Fill in the Description }}

## OUTPUTS

### System.Boolean

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/Test-Credential.html)
