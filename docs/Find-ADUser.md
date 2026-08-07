---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Find-ADUser
---

# Find-ADUser

## SYNOPSIS

Finds enabled AD users matching a partial name, username, or display name.

## SYNTAX

### __AllParameterSets

```
Find-ADUser [-SearchString] <string> [-WhatIf] [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Searches Active Directory for user objects using ANR (Ambiguous Name Resolution), excluding disabled accounts (UAC 1.2).
Returns full [ADUser] objects with all properties loaded.

## EXAMPLES

### EXAMPLE 1

Find-ADUser "tim"
Returns all enabled AD users matching "tim" in name, username, or display name.

### EXAMPLE 2

"tim" | Find-ADUser
Demonstrates pipeline input.

## PARAMETERS

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- cf
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

### -SearchString

Enter part of the name, username, or display name to search for.
This is a mandatory parameter and supports pipeline input.

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

### -WhatIf

Runs the command in a mode that only reports what would happen without performing the actions.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: ''
SupportsWildcards: false
Aliases:
- wi
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

{{ Fill in the Description }}

## OUTPUTS

### Microsoft.ActiveDirectory.Management.ADUser

{{ Fill in the Description }}

## NOTES

Author: Greg Pennings
Supports -WhatIf and -Confirm via CmdletBinding.


## RELATED LINKS

- [Get-ADUser]()
- [](https://gregpennings.github.io/PowerShellAdminModule/Find-ADUser.html)
