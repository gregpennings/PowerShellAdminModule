---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Get-VMInfoAllVMs
---

# Get-VMInfoAllVMs

## SYNOPSIS

Returns inventory information for all VMs across VMware, Nutanix, and/or Hyper-V.

## SYNTAX

### __AllParameterSets

```
Get-VMInfoAllVMs [[-Platform] <string>] [[-Path] <string>] [-ExportCsv]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Queries all VMs and returns their inventory details as objects.
By default
all platforms -- VMware (vSphere), Nutanix (Prism), and Hyper-V -- are
queried, and the objects are emitted to the pipeline so you can sort, filter,
format, or export them.

Hyper-V is queried over the CIM sessions mounted by Connect-HyperVHost;
clustered VMs are deduped by VM id.
If no Hyper-V hosts are connected, the
Hyper-V pass is skipped with a warning.

Use -ExportCsv to write the results to timestamped CSV file(s) instead --
one file per platform, named via New-FileNameWithTimestamp.
In that mode the
function returns the file path(s) rather than the VM objects.

## EXAMPLES

### EXAMPLE 1

Get-VMInfoAllVMs
Returns all VMware and Nutanix VM objects to the pipeline.

### EXAMPLE 2

Get-VMInfoAllVMs -Platform VMware | Where-Object PowerState -eq 'PoweredOn'
Returns only VMware VMs, filtered to those powered on.

### EXAMPLE 3

Get-VMInfoAllVMs -ExportCsv
Writes one timestamped CSV per queried platform (AllVMwareVMInfo /
AllNutanixVMInfo / AllHyperVVMInfo) and returns the file paths.

## PARAMETERS

### -ExportCsv

Write results to CSV file(s) and return the path(s) instead of the VM
objects.
One file per platform queried.

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

### -Path

Output directory for the CSV file(s) when -ExportCsv is used.
Defaults to
C:\temp (created if it does not exist).

```yaml
Type: System.String
DefaultValue: $script:AdminConfig.DefaultExportPath
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

### -Platform

Which platform(s) to query: VMware, Nutanix, HyperV, or All (default).
'Both' is accepted as a back-compat synonym for All.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

Replaces the former Get-VMInfoAllVMs_CSV (which always exported to C:\temp).


## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/Get-VMInfoAllVMs.html)
