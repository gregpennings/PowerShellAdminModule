---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Get-CredExpiration
---

# Get-CredExpiration

## SYNOPSIS

On-demand credential/certificate expiration checker.

## SYNTAX

### __AllParameterSets

```
Get-CredExpiration [[-WarningWindowDays] <int>] [[-OutDir] <string>] [[-LogFileName] <string>]
 [[-CsvFileName] <string>] [[-LookbackDays] <string>] [-IncludeAll] [-ExportResults]
 [-IncludeSummary]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Connects live to Microsoft Graph (no manual CSV export needed) and checks
App Registrations + Enterprise Applications (Service Principals) for
expiring or expired secrets/certificates.

Requires: Application.Read.All (already admin-consented as of today)

On first run in a session, you'll be prompted to sign in via device code
(a browser window will open).

## EXAMPLES

### EXAMPLE 1

Get-CredExpiration

### EXAMPLE 2

Get-CredExpiration -IncludeAll -ExportResults -WarningWindowDays 45

### EXAMPLE 3

Get-CredExpiration -LookbackDays All -IncludeSummary

## PARAMETERS

### -CsvFileName

{{ Fill CsvFileName Description }}

```yaml
Type: System.String
DefaultValue: expiration_report.csv
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 3
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -ExportResults

Write the log + CSV to -OutDir.
Off by default (console output only).

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

### -IncludeAll

Report on every secret/certificate, not just expired/expiring ones.

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

### -IncludeSummary

Print the Expired / Expiring Soon count summary at the bottom of the console
output.
Off by default.

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

### -LogFileName

{{ Fill LogFileName Description }}

```yaml
Type: System.String
DefaultValue: expiration_report.log
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

### -LookbackDays

How far into the past to still report already-expired credentials.
'All' reports every expired credential no matter how long ago it expired.
A number (default 90) hides expired credentials older than that many days;
credentials that are OK or expiring soon are never affected by this.

```yaml
Type: System.String
DefaultValue: 90
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 4
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -OutDir

Directory for the log/CSV when -ExportResults is used.

```yaml
Type: System.String
DefaultValue: C:\temp\CredExpiration
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

### -WarningWindowDays

Days out to flag a credential as "Expiring Soon" (default 30).

```yaml
Type: System.Int32
DefaultValue: 30
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

## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/Get-CredExpiration.html)
