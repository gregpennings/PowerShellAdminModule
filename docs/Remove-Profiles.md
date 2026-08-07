---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Remove-Profiles
---

# Remove-Profiles

## SYNOPSIS

Removes non-loaded, non-special user profiles from a computer.

## SYNTAX

### ByComputerName (Default)

```
Remove-Profiles [-ComputerName <string>] [-WhatIf] [-Confirm]
```

### ByPipeline

```
Remove-Profiles -InputObject <ciminstance> [-WhatIf] [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Two ways to use this:
  - Standalone: pass -ComputerName and it queries and removes every
    non-loaded, non-special Win32_UserProfile on that computer itself
    (same behavior as the old Remove-ProfilesFromRemoteComputer).
  - Piped: pipe Win32_UserProfile instances in (e.g.
from Get-Profiles,
    optionally filtered first) and only those exact profiles are removed.
This permanently removes the profile(s), including on-disk data.
Supports -WhatIf / -Confirm and prompts before each deletion by default.

## EXAMPLES

### EXAMPLE 1

Remove-Profiles -ComputerName SERVER01 -WhatIf
Shows which profiles would be removed without deleting them.

### EXAMPLE 2

Remove-Profiles -ComputerName SERVER01 -Confirm:$false
Removes every candidate profile on SERVER01 without prompting.

### EXAMPLE 3

Get-Profiles -ComputerName SERVER01 | Where-Object { $_.LastUseTime -lt (Get-Date).AddDays(-90) } | Remove-Profiles
Removes only the profiles unused for 90+ days.

## PARAMETERS

### -ComputerName

The computer to clean up.
Defaults to the local computer.
Ignored when
profiles are piped in.

```yaml
Type: System.String
DefaultValue: $env:COMPUTERNAME
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByComputerName
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

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

### -InputObject

A Win32_UserProfile CIM instance to remove, typically piped in from
Get-Profiles.

```yaml
Type: Microsoft.Management.Infrastructure.CimInstance
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByPipeline
  Position: Named
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

### Microsoft.Management.Infrastructure.CimInstance

{{ Fill in the Description }}

## OUTPUTS

## NOTES

## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/Remove-Profiles.html)
