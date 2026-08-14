---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Get-LoggedOnSessions
---

# Get-LoggedOnSessions

## SYNOPSIS

Returns the logged-on sessions of a computer as objects.

## SYNTAX

### __AllParameterSets

```
Get-LoggedOnSessions [[-ComputerName] <string>] [-Select]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Runs quser against the target computer and parses the output into objects.
Read-only -- it does not log anyone off (use Clear-LoggedOnSessions for that).
Pipe to Out-GridView (ogv), Where-Object, Format-Table, etc.
as needed, or
pipe straight to Clear-LoggedOnSessions to log off just the sessions you've
filtered to.

## EXAMPLES

### EXAMPLE 1

Get-LoggedOnSessions -ComputerName RDS01
Returns every session on RDS01 as objects (no grid view).

### EXAMPLE 2

Get-LoggedOnSessions -ComputerName RDS01 -Select
Opens a grid view (Out-GridView) listing every session on RDS01; returns only
the ones you pick and click OK.

### EXAMPLE 3

Get-LoggedOnSessions -ComputerName RDS01 -Select | Clear-LoggedOnSessions
Pick sessions from the grid view here, then log off exactly those --
Clear-LoggedOnSessions logs off whatever it receives on the pipeline without
showing its own picker, using each session's own ComputerName as the target.

### EXAMPLE 4

Get-LoggedOnSessions -ComputerName RDS01 | Where-Object State -eq 'Disc' | Clear-LoggedOnSessions
Logs off only the disconnected sessions on RDS01.

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

### -Select

Show the sessions in a grid view (Out-GridView) and return only the
ones you pick, instead of returning every session.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: 'False'
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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### PSCustomObject (ComputerName

{{ Fill in the Description }}

### System.Management.Automation.PSObject

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/Get-LoggedOnSessions.html)
