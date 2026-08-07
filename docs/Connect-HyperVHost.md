---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Connect-HyperVHost
---

# Connect-HyperVHost

## SYNOPSIS

"Mounts" one or more Hyper-V hosts by opening CIM sessions the VM-info
functions reuse. The Hyper-V analog of Connect-VIServer / Connect-PrismCentral.

## SYNTAX

### ByName (Default)

```
Connect-HyperVHost [[-ComputerName] <string[]>] [-Credential <pscredential>] [-PassThru]
```

### FromAD

```
Connect-HyperVHost -FromAD [-Server <string>] [-SearchBase <string>] [-Credential <pscredential>]
 [-PassThru]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Hyper-V has no central management point and no ambient connection: every
Hyper-V cmdlet reaches a host explicitly.
This function opens a CIM session
to each host and stores it module-scoped, keyed by computer name, so
Get-VMInfo / Get-VMInfoAllVMs (Platform HyperV) can query them without
re-connecting each call.

Call this once at startup -- e.g.
from your PowerShell profile, right where
you Connect-VIServer / Connect-PrismCentral -- to keep the sessions warm for
the session's lifetime.
Re-running it for a host that is already connected
replaces the old session (so it is safe to call again after a host reboots).

Three ways to supply the host list:
  -ComputerName    explicit names (default: the configured HyperVHosts)
  -FromAD          discover every Hyper-V host from Active Directory
  (config)         with no -ComputerName, falls back to
                   (Get-AdminConfig).HyperVHosts -- set it once with
                   Set-AdminConfig -Name HyperVHosts -Value @('host1','host2').

-FromAD is the zero-maintenance option: it queries the "Microsoft Hyper-V"
service connection points each host publishes (see Get-HyperVHostFromAD), so
new hosts appear automatically.
Use -Server for a different domain/forest.

Authentication uses your current identity by default; pass -Credential for
workgroup hosts or a separate admin account.

Standalone and clustered hosts are both fine: connect to each standalone host
and to every node of each failover cluster.
A clustered VM is returned by
whichever node currently owns it, and Get-VMInfo dedupes by VM id, so listing
all nodes never double-counts.

## EXAMPLES

### EXAMPLE 1

Connect-HyperVHost -ComputerName hv01,hv02
Opens CIM sessions to two standalone hosts using the current identity.

### EXAMPLE 2

Connect-HyperVHost -FromAD
Discovers every Hyper-V host in the current domain and mounts them all.

### EXAMPLE 3

Connect-HyperVHost -FromAD -Server hci.pvt
Same, but discovers from the hci.pvt domain (use this in your profile).

### EXAMPLE 4

Set-AdminConfig -Name HyperVHosts -Value @('hv01','hv02','clusternodeA','clusternodeB')
Connect-HyperVHost
Persists the host list once, then connects them all from config (e.g. in your profile).

### EXAMPLE 5

Connect-HyperVHost -ComputerName wrkgrp-hv01 -Credential (Get-Credential)
Connects a workgroup host with an explicit credential.

### EXAMPLE 6

Get-VMInfo SERVER01 -Platform HyperV
After connecting, query Hyper-V like any other platform.

## PARAMETERS

### -ComputerName

One or more Hyper-V host names to connect.
Defaults to the configured
HyperVHosts list (Get-AdminConfig).HyperVHosts.

```yaml
Type: System.String[]
DefaultValue: $script:AdminConfig.HyperVHosts
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

### -Credential

Optional credential for hosts that do not accept your current identity
(workgroup, different domain, or a dedicated admin account).
With -FromAD it
is also used for the AD discovery query.

```yaml
Type: System.Management.Automation.PSCredential
DefaultValue: ''
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

### -FromAD

Discover the host list from Active Directory (via Get-HyperVHostFromAD)
instead of -ComputerName/config.
Mounts every Hyper-V host AD knows about.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: FromAD
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -PassThru

Return the CIM session objects that were opened (or already open).
By default
the function is quiet and stores the sessions without emitting them.

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

### -SearchBase

With -FromAD, limit AD discovery to a specific OU/container DN.
Ignored
without -FromAD.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: FromAD
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Server

With -FromAD, the domain or DC to query for hosts (e.g.
hci.pvt).
Omit to
use the current domain.
Ignored without -FromAD.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: FromAD
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

### None by default; Microsoft.Management.Infrastructure.CimSession with -PassThru.

{{ Fill in the Description }}

### Microsoft.Management.Infrastructure.CimSession

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/Connect-HyperVHost.html)
