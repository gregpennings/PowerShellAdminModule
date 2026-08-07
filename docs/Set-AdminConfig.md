---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Set-AdminConfig
---

# Set-AdminConfig

## SYNOPSIS

Sets a persistent Admin module configuration value.

## SYNTAX

### __AllParameterSets

```
Set-AdminConfig [-Name] <string> [-Value] <Object> [[-Scope] <string>] [-WhatIf] [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Writes a setting to one of the override config files that live OUTSIDE the
repo, so the value survives every 'git pull':

  -Scope User    (default)  %APPDATA%\Admin\Admin.Config.psd1   (per-user, wins)
  -Scope Machine            %ProgramData%\Admin\Admin.Config.psd1 (per-machine)

These layer on top of the repo's baseline Admin.Config.psd1.
After writing,
the in-memory configuration is rebuilt so Get-AdminConfig reflects the
change immediately.
This is the Set-PowerCLIConfiguration-style "set it
once" knob for your environment.

## EXAMPLES

### EXAMPLE 1

Set-AdminConfig -Name DefaultExportPath -Value 'D:\Reports'
Persists your personal default export path; survives repo pulls.

### EXAMPLE 2

Set-AdminConfig -Name PsExecPath -Value 'C:\tools\psexec.exe' -Scope Machine
Sets a machine-wide PsExec path override.

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

### -Name

The setting name, e.g.
PsExecPath or DefaultExportPath, or any new key you
want to keep (e.g.
a default vCenter list).

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

### -Scope

Where to persist: User (per-user, default) or Machine (per-machine).
Writing Machine scope requires permission to %ProgramData%.

```yaml
Type: System.String
DefaultValue: User
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 2
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Value

The value to store.
Strings and string arrays are supported.

```yaml
Type: System.Object
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: true
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

- [](https://gregpennings.github.io/PowerShellAdminModule/Set-AdminConfig.html)
