---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Enable-WinRMSSL
---

# Enable-WinRMSSL

## SYNOPSIS

Enables WinRM over HTTPS (SSL) on a computer using PsExec.

## SYNTAX

### __AllParameterSets

```
Enable-WinRMSSL [[-ComputerName] <string>] [[-PsExecPath] <string>] [-WhatIf] [-Confirm]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Runs 'winrm.cmd quickconfig -transport:https' remotely via PsExec (under the
SYSTEM account) to configure the WinRM HTTPS listener.
Requires PsExec
(see Get-AdminConfig / Set-AdminConfig PsExecPath), SMB/RPC reachability,
and a suitable server certificate on the target for the HTTPS listener.

## EXAMPLES

### EXAMPLE 1

Enable-WinRMSSL -ComputerName SERVER01
Configures the WinRM HTTPS listener on SERVER01.

## PARAMETERS

### -ComputerName

The target computer.
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

### -PsExecPath

Path to the PsExec executable.
Defaults to the configured PsExecPath.

```yaml
Type: System.String
DefaultValue: $script:AdminConfig.PsExecPath
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

### None.

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/Enable-WinRMSSL.html)
