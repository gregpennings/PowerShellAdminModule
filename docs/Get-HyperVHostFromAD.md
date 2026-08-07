---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Get-HyperVHostFromAD
---

# Get-HyperVHostFromAD

## SYNOPSIS

Discovers Hyper-V hosts from Active Directory and returns their DNS host names.

## SYNTAX

### __AllParameterSets

```
Get-HyperVHostFromAD [[-Server] <string>] [[-SearchBase] <string>] [[-Credential] <pscredential>]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Every Hyper-V host publishes a service connection point (SCP) named
"Microsoft Hyper-V" under its own computer object in AD.
This function finds
those SCPs and resolves each one to its parent computer's DNS host name, so
you get the full set of Hyper-V hosts without maintaining a static list.

This catches standalone hosts and every node of a failover cluster (each node
publishes its own SCP).
Filtering computers by operating system would NOT
work -- a Windows Server with the Hyper-V role reports an ordinary Server OS.

Pipe the result straight into Connect-HyperVHost, or just use
'Connect-HyperVHost -FromAD', which calls this for you.

## EXAMPLES

### EXAMPLE 1

Get-HyperVHostFromAD
Lists every Hyper-V host registered in the current domain.

### EXAMPLE 2

Get-HyperVHostFromAD -Server hci.pvt
Discovers hosts in the hci.pvt domain (e.g. when your account is elsewhere).

### EXAMPLE 3

Connect-HyperVHost -ComputerName (Get-HyperVHostFromAD -Server hci.pvt)
Discovers and mounts them in one step (or just: Connect-HyperVHost -FromAD -Server hci.pvt).

## PARAMETERS

### -Credential

Credential for the AD query, if the current identity can't read the target
domain.

```yaml
Type: System.Management.Automation.PSCredential
DefaultValue: ''
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

### -SearchBase

Limit the SCP search to a specific OU/container distinguished name.
Omit to
search the whole domain.

```yaml
Type: System.String
DefaultValue: ''
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

### -Server

Domain or domain controller to query.
Omit to use the current domain.
Use
this when the Hyper-V hosts live in a different domain/forest than your
account (e.g.
-Server hci.pvt).

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.String -- one DNS host name per discovered Hyper-V host

{{ Fill in the Description }}

### System.String

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/Get-HyperVHostFromAD.html)
