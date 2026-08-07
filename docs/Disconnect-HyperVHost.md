---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Disconnect-HyperVHost
---

# Disconnect-HyperVHost

## SYNOPSIS

Closes Hyper-V CIM sessions opened by Connect-HyperVHost and drops them
from the module session store.

## SYNTAX

### __AllParameterSets

```
Disconnect-HyperVHost [[-ComputerName] <string[]>] [-WhatIf] [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Removes the underlying CIM session(s) and forgets them.
With no
-ComputerName, disconnects every mounted host.
Safe to call for hosts that
are not connected (they are simply skipped).

## EXAMPLES

### EXAMPLE 1

Disconnect-HyperVHost
Closes every mounted Hyper-V session.

### EXAMPLE 2

Disconnect-HyperVHost -ComputerName hv01
Closes just the session to hv01.

## PARAMETERS

### -ComputerName

One or more host names to disconnect.
Omit to disconnect all mounted hosts.

```yaml
Type: System.String[]
DefaultValue: ''
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

## OUTPUTS

## NOTES

## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/Disconnect-HyperVHost.html)
