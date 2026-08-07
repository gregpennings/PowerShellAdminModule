---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Get-AdminConfig
---

# Get-AdminConfig

## SYNOPSIS

Returns the effective Admin module configuration.

## SYNTAX

### __AllParameterSets

```
Get-AdminConfig [-ListPaths]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Shows the merged, effective settings the module uses (PsExec path,
privileged account, domain controller, AD search base, RD session prefix,
default export path, plus any custom keys you have added).

Settings are layered, later overriding earlier:
  1.
Repo Admin.Config.psd1        (baseline, deploys via git pull)
  2.
%ProgramData%\Admin\...psd1   (per-machine override)
  3.
%APPDATA%\Admin\...psd1       (per-user override, wins)

Use Set-AdminConfig to persist overrides.
Use -ListPaths to see the layer
file locations and which ones currently exist.

## EXAMPLES

### EXAMPLE 1

Get-AdminConfig
Lists the effective settings.

### EXAMPLE 2

(Get-AdminConfig).PsExecPath
Returns just the configured PsExec path.

### EXAMPLE 3

Get-AdminConfig -ListPaths
Shows the Repo / Machine / User config file paths and which exist.

## PARAMETERS

### -ListPaths

Instead of the settings, return the config layer files and whether each
exists, in precedence order.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/Get-AdminConfig.html)
