---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Update-PowerShell
---

# Update-PowerShell

## SYNOPSIS

Updates PowerShell 7 to the latest release using the recommended installer,
with a version check, an elevation check, and -WhatIf support.

## SYNTAX

### __AllParameterSets

```
Update-PowerShell [[-Version] <string>] [-ListVersions] [-UseMSI] [-Preview] [-Force] [-Quiet]
 [-WhatIf] [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

A guard-railed wrapper around the established update methods:

  - Looks up the latest release and SKIPS the update if the running version
    is already current (override with -Force).
  - Prefers winget (Microsoft's recommended installer on Windows) when it is
    available; otherwise falls back to the official bootstrap script
    'https://aka.ms/install-powershell.ps1 -UseMSI' -- the long-standing
    manual method.
Force the MSI path explicitly with -UseMSI.
  - The MSI path requires an elevated session (the machine-wide install needs
    administrator rights); the function checks and fails fast if you are not
    elevated rather than letting the MSI silently no-op.
  - Installs software, so it supports -WhatIf/-Confirm and defaults to
    ConfirmImpact High (it prompts before changing anything).

For a specific version (including reverting to an older 7.x) or to list recent
releases, -Version / -ListVersions delegate to the standalone, in-place MSI
installer shipped alongside the module (Install-PowerShell7.ps1).
That same
script can BOOTSTRAP PowerShell 7 from Windows PowerShell 5.1, where this
module cannot load -- run it directly there.

You are updating the pwsh you launch NEXT -- the current session keeps its
version until you start a new one.

## EXAMPLES

### EXAMPLE 1

Update-PowerShell
Updates to the latest stable release if a newer one exists; otherwise reports
that you are current.

### EXAMPLE 2

Update-PowerShell -WhatIf
Shows the method and target version that would be used, without installing.

### EXAMPLE 3

Update-PowerShell -UseMSI -Quiet
Forces the official MSI bootstrap (your proven manual method) and installs silently.

### EXAMPLE 4

Update-PowerShell -ListVersions
Lists recent PowerShell releases.

### EXAMPLE 5

Update-PowerShell -Version 7.4.6
Installs (or reverts to) exactly 7.4.6 via the in-place MSI installer.

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

### -Force

Install even if the running version already matches the latest release,
and close other running pwsh.exe processes (that could lock files the
update needs to replace) without prompting first.

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

### -ListVersions

List recent PowerShell releases and return, without installing anything.

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

### -Preview

Install the latest preview build instead of the latest stable.
With
-ListVersions, include preview releases in the list.

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

### -Quiet

Run the installer silently (no UI).

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

### -UseMSI

Force the install-powershell.ps1 + MSI path even when winget is available.
(Ignored with -Version, which always uses the per-version MSI installer.)

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

### -Version

Install (or revert to) an exact version, e.g.
7.4.6.
Delegates to
Install-PowerShell7.ps1 (in-place MSI).
Skips the "already latest" check.

```yaml
Type: System.String
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

Equivalent manual one-liner (what -UseMSI runs under the hood):
    Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI"


## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/Update-PowerShell.html)
