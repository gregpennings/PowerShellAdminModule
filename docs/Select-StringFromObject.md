---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Select-StringFromObject
---

# Select-StringFromObject

## SYNOPSIS

Greps the formatted text of pipeline objects -- Out-String -Stream | Select-String.

## SYNTAX

### __AllParameterSets

```
Select-StringFromObject [-Pattern] <string[]> [-InputObject <psobject>] [-CaseSensitive]
 [-SimpleMatch] [-NotMatch] [-Context <int>] [-Width <int>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Renders the piped input the way it would display in the console (via
Out-String -Stream) and runs Select-String over those lines, returning the
matching lines.
This packages the common idiom

    <command> | Out-String -Stream | Select-String <pattern>

into a single grep-like step.
The alias 'grep' is provided.

All input is collected and formatted ONCE before matching, so table
headers and column alignment are preserved (formatting per-object would
repeat headers and misalign columns).

## EXAMPLES

### EXAMPLE 1

Get-ADUserGroupMembership jdoe | grep sql
Lists jdoe's groups and keeps only the lines mentioning "sql".

### EXAMPLE 2

Get-Process | grep -Pattern 'chrome','msedge'
Shows the process-table lines for either browser.

### EXAMPLE 3

Get-Service | grep -SimpleMatch -NotMatch Running
Shows the service lines that are not running.

### EXAMPLE 4

Get-VMInfo | grep -Width 4096 10.1.2
Widens the rendered table so a column isn't truncated before matching.

## PARAMETERS

### -CaseSensitive

Match case-sensitively.
By default matching is case-insensitive.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
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

### -Context

Number of lines of context to capture around each match (Select-String -Context).

```yaml
Type: System.Int32
DefaultValue: 0
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

### -InputObject

The objects to render and search.
Accepts pipeline input.

```yaml
Type: System.Management.Automation.PSObject
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: Named
  IsRequired: false
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -NotMatch

Return the lines that do NOT match (Select-String -NotMatch).

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
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

### -Pattern

One or more regular-expression patterns to match (passed to Select-String).
Use -SimpleMatch to treat them as literal text instead.

```yaml
Type: System.String[]
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

### -SimpleMatch

Treat Pattern as literal text rather than a regular expression.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
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

### -Width

Line width used when rendering objects to text.
Defaults to the host width;
set a larger value (e.g.
4096) to stop wide tables being truncated before
the match is searched.

```yaml
Type: System.Int32
DefaultValue: 0
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

### System.Management.Automation.PSObject

{{ Fill in the Description }}

## OUTPUTS

### Microsoft.PowerShell.Commands.MatchInfo (one per matching line).

{{ Fill in the Description }}

## NOTES

Because it searches the FORMATTED text, matches depend on how the objects
display (default table columns, truncation at the render width).
For matching
on actual property values, prefer Where-Object.


## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/Select-StringFromObject.html)
