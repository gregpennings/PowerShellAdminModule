---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Get-HyperVSession
---

# Get-HyperVSession

## SYNOPSIS

Returns the Hyper-V CIM sessions currently mounted by Connect-HyperVHost.

## SYNTAX

### __AllParameterSets

```
Get-HyperVSession
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Read-only view of the module-scoped Hyper-V session store that
Get-VMInfo / Get-VMInfoAllVMs (Platform HyperV) query.
Use it to confirm
which hosts are connected and the state of each session.

## EXAMPLES

### EXAMPLE 1

Get-HyperVSession
Lists the connected Hyper-V hosts and their session state.

### EXAMPLE 2

Get-HyperVSession | Select-Object ComputerName, InstanceId
Projects just the identity of each open session.

## PARAMETERS

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Microsoft.Management.Infrastructure.CimSession (one per connected host).

{{ Fill in the Description }}

### Microsoft.Management.Infrastructure.CimSession

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/Get-HyperVSession.html)
