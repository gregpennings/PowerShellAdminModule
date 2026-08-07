---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Start-RDP
---

# Start-RDP

## SYNOPSIS

Opens an RDP session to a computer using a supplied credential.

## SYNTAX

### __AllParameterSets

```
Start-RDP [-ComputerName] <string> [-Cred] <pscredential>
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Stores the credential for the target with cmdkey, writes a temporary .rdp
file (signed with the first Code Signing certificate in CurrentUser\My if one
exists), launches mstsc against it, then schedules a background job to remove
the stored credential and temp file after 30 seconds.

## EXAMPLES

### EXAMPLE 1

Start-RDP -ComputerName SERVER01 -Cred (Get-Credential)

### EXAMPLE 2

$cred = Get-MyCredential -CredPath C:\creds\admin.xml
Start-RDP SERVER01 -Cred $cred
Start-RDP SERVER02 -Cred $cred
Load an admin credential once (positional ComputerName) and reuse it across
several RDP sessions.

## PARAMETERS

### -ComputerName

The target computer / RDP host.

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

### -Cred

The credential used for the session.

```yaml
Type: System.Management.Automation.PSCredential
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: (All)
  Position: 1
  IsRequired: true
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

SECURITY: the password is passed to cmdkey on the command line
(/pass:<password>), so it is briefly visible to anyone who can enumerate
process command lines on this machine.
The stored credential is removed by a
background job ~30 seconds later.


## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/Start-RDP.html)
