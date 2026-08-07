---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Get-SystemInfo
---

# Get-SystemInfo

## SYNOPSIS

Gets a broad set of hardware, OS, network, memory, and open-port details for
a computer (local or remote).

## SYNTAX

### __AllParameterSets

```
Get-SystemInfo [-ComputerName] <string> [-IgnorePing]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Queries the target via CIM (Win32_ComputerSystem, Win32_LogicalDisk,
Win32_NetworkAdapterConfiguration, Win32_Processor, Win32_Bios,
Win32_OperatingSystem), does a DNS lookup, scans a few common TCP ports, and
presents a consolidated report as a sorted table and an Out-GridView.

## EXAMPLES

### EXAMPLE 1

Get-SystemInfo -ComputerName HQSPDBSP01

### EXAMPLE 2

Get-SystemInfo -ComputerName SERVER01 -IgnorePing

## PARAMETERS

### -ComputerName

The computer to inspect.

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

### -IgnorePing

Attempt data collection even if the computer does not reply to ping.

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

### None (writes a formatted table and an Out-GridView).

{{ Fill in the Description }}

## NOTES

Uses CIM (WS-Management) for remote queries; the target must have WinRM
enabled.
Original concept: sqlpowershell.wordpress.com.


## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/Get-SystemInfo.html)
