---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: ConvertTo-TransposedObject
---

# ConvertTo-TransposedObject

## SYNOPSIS

Transpose properties of objects from columns to rows.

## SYNTAX

### __AllParameterSets

```
ConvertTo-TransposedObject [[-InputObject] <Object>] [[-Title] <string>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Transpose properties of objects from columns to rows.
Useful when the order displayed in a GridView (with
Out-GridView) or in a CSV file (with Export-Csv) should be rotated.
It uses the name property or a given property as new property names (column headers) if it exists.

## EXAMPLES

### EXAMPLE 1

dir | Transpose-Object | Out-GridView

Shows directory listing with a column instead of a row for every file/directory

### EXAMPLE 2

ps | Transpose-Object | Export-Csv Processes.csv -Delimiter ';' -NoTypeInformation

Creates a CSV file with a column instead of a row for every process

## PARAMETERS

### -InputObject

{{ Fill InputObject Description }}

```yaml
Type: System.Object
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 0
  IsRequired: false
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Title

Name of property whose values are used as titles

```yaml
Type: System.String
DefaultValue: Name
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Object

{{ Fill in the Description }}

### System.Object

{{ Fill in the Description }}

## OUTPUTS

### Transposed object

{{ Fill in the Description }}

## NOTES

Name: Transpose-Object
Author: Markus Scholtes
Version: 1.2 - values of 0, $FALSE or "" not longer identified as $NULL
Creation Date: 20/03/2023


## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/ConvertTo-TransposedObject.html)
