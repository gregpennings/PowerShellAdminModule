---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Get-VMInfo
---

# Get-VMInfo

## SYNOPSIS

Lists VM info from VMware vCenter(s), Nutanix Prism Central(s), and
Hyper-V host(s).

## SYNTAX

### ByName (Default)

```
Get-VMInfo [[-VM] <string>] [-Platform <string>] [-NoResolveDns]
```

### ByIPExact

```
Get-VMInfo -IPExact <string> [-Platform <string>] [-NoResolveDns]
```

### ByIPLike

```
Get-VMInfo -IPLike <string> [-Platform <string>] [-NoResolveDns]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Queries every connected vCenter, Prism Central, and Hyper-V host for VMs
that match the selection criteria, normalizes all platforms into a single
object shape, and returns one uniform collection.
Assumes connections are
already established (see profile: Connect-VIServer / Connect-PrismCentral /
Connect-HyperVHost).

Hyper-V has no ambient connection, so its hosts must be mounted first with
Connect-HyperVHost (CIM sessions held by the module).
Clustered Hyper-V VMs
are deduped by VM id, so connecting every cluster node never double-counts.

VMs can be selected by name (default), by exact IP, or by partial IP.

## EXAMPLES

### EXAMPLE 1

Get-VMInfo web01

### EXAMPLE 2

Get-VMInfo -IPExact 1.2.3.4

### EXAMPLE 3

Get-VMInfo -IPLike 10.1.2 -Platform Nutanix

### EXAMPLE 4

Connect-HyperVHost -ComputerName hv01,hv02
Get-VMInfo SERVER01 -Platform HyperV
Mount the Hyper-V hosts once, then query them like any other platform.

### EXAMPLE 5

Get-VMInfo SERVER01 | Select-Object Name, DnsName, IPAddresses
Looks up a VM by name and projects just the identity columns.

## PARAMETERS

### -IPExact

Return VMs whose guest IP matches this address exactly.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByIPExact
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -IPLike

Return VMs whose guest IP contains this substring (e.g.
a subnet "10.1.2").

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByIPLike
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -NoResolveDns

Skip reverse-DNS resolution.
By default, rows the hypervisor doesn't
supply a DnsName for (Nutanix, or VMware without guest tools) have
their first IP reverse-resolved to its registered network name; this
adds one DNS lookup per such row, so pass -NoResolveDns on large sweeps.

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

### -Platform

Limit the query to one platform (VMware, Nutanix, or HyperV).
Defaults to
All.
'Both' is accepted as a back-compat synonym for All (it predates
Hyper-V support, when there were only two platforms).

```yaml
Type: System.String
DefaultValue: All
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

### -VM

VM name (or substring) to match.
Defaults to the local computer name.

```yaml
Type: System.String
DefaultValue: $env:COMPUTERNAME
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByName
  Position: 0
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

### PSCustomObject with a common set of properties across platforms

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/Get-VMInfo.html)
