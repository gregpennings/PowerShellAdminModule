---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-14-2026
PlatyPS schema version: 2024-05-01
title: Update-VMInfoCache
---

# Update-VMInfoCache

## SYNOPSIS

Rebuilds the on-disk cache that Get-VMInfo reads from by default.

## SYNTAX

### __AllParameterSets

```
Update-VMInfoCache [[-Platform] <string>] [-NoResolveDns]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Runs the full live query -- every connected vCenter, Prism Central, and
mounted Hyper-V host, including the per-VM tag/snapshot/datastore/disk
lookups and reverse-DNS resolution (same as Get-VMInfo -Live) -- and writes
the result plus a timestamp to:

    $env:LOCALAPPDATA\Admin\VMInfoCache.xml

This is the slow pass. Run it once (a good place is your profile, right
after Connect-VIServer / Connect-PrismCentral / Connect-HyperVHost) and
Get-VMInfo's default cached reads become near-instant, in-memory filters
over the cached collection -- no network calls, no per-VM round trips.

Assumes connections are already established, same as Get-VMInfo.

## EXAMPLES

### EXAMPLE 1

Update-VMInfoCache
Rebuilds the cache from every connected platform.

### EXAMPLE 2

Connect-HyperVHost -FromAD
Update-VMInfoCache
Typical profile sequence: mount Hyper-V hosts, then warm the cache.

## PARAMETERS

### -Platform

Which platform(s) to include when rebuilding the cache. Defaults to All.
Narrowing this means Get-VMInfo's cached reads for the excluded
platform(s) will come back empty until you rebuild with them included.

```yaml
Type: System.String
DefaultValue: All
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

### -NoResolveDns

Skip reverse-DNS resolution while rebuilding the cache (see Get-VMInfo).
Rows the hypervisor didn't supply a DnsName for will have a blank
DnsName in every cached read until the cache is rebuilt without this
switch.

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

- [](https://gregpennings.github.io/PowerShellAdminModule/Update-VMInfoCache.html)
