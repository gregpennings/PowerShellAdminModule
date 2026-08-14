---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Clear-LoggedOnSessions
---

# Clear-LoggedOnSessions

## SYNOPSIS

Logs off user sessions on a remote computer.

## SYNTAX

### ByComputerName (Default)

```
Clear-LoggedOnSessions -ComputerName <string> [-Select] [-WhatIf] [-Confirm]
```

### ByPipeline

```
Clear-LoggedOnSessions -InputObject <psobject> [-WhatIf] [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Two ways to use this:
  - Standalone: pass -ComputerName and it enumerates every logged-on
    session on that computer (via quser).
By default (-Select is on)
    it shows them in a grid view (Out-GridView) so you pick which ones
    to log off. Pass -Select:$false to log off every session without
    the picker.
  - Piped: pipe session objects in (e.g.
from Get-LoggedOnSessions,
    optionally filtered first) and only those exact sessions are
    logged off.

Handles both RDP-named sessions (rdp-tcp#NN, via 'logoff' on the host) and
numeric session IDs (via Invoke-RDUserLogoff).

Supports -WhatIf / -Confirm.
Use -WhatIf to preview which sessions would be
logged off before committing -- recommended with -Select:$false.

## EXAMPLES

### EXAMPLE 1

Clear-LoggedOnSessions -ComputerName RDS01
Opens a grid view (Out-GridView) listing every session on RDS01; logs off only
the ones you pick and click OK.

### EXAMPLE 2

Clear-LoggedOnSessions -ComputerName RDS01 -Select:$false
Logs off ALL sessions on RDS01, no picker.

### EXAMPLE 3

Clear-LoggedOnSessions -ComputerName RDS01 -Select:$false -WhatIf
Shows which sessions would be logged off, without doing it.

### EXAMPLE 4

Get-LoggedOnSessions -ComputerName RDS01 -Select | Clear-LoggedOnSessions
Picks sessions from a grid view in Get-LoggedOnSessions, then logs off exactly
those -- Clear-LoggedOnSessions logs off whatever it receives on the pipeline
without showing its own picker. Each piped session carries its own
ComputerName, so this also works if the piped sessions span more than one
computer.

### EXAMPLE 5

Get-LoggedOnSessions -ComputerName RDS01 | Where-Object State -eq 'Disc' | Clear-LoggedOnSessions
Logs off only the disconnected sessions on RDS01.

## PARAMETERS

### -ComputerName

The remote computer whose sessions will be logged off.
Mandatory (there is
no local default) to avoid accidentally logging everyone off this machine.
Ignored when sessions are piped in.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases:
- RemoteComputerName
ParameterSets:
- Name: ByComputerName
  Position: Named
  IsRequired: true
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

A session object to log off, typically piped in from Get-LoggedOnSessions.
Each object's own ComputerName property is used as the logoff target, so
piped sessions from different computers are each sent to the right host.

```yaml
Type: System.Management.Automation.PSObject
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

### -Select

Show a grid view of the sessions and log off only the ones you select.
Defaults to on. Pass -Select:$false to log off every session on the
computer without the picker.
Ignored when sessions are piped in.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: 'True'
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

### System.Management.Automation.PSObject

{{ Fill in the Description }}

## OUTPUTS

## NOTES

## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/Clear-LoggedOnSessions.html)
