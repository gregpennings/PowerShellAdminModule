---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Get-MyCredential
---

# Get-MyCredential

## SYNOPSIS

Loads a stored PSCredential from a file, creating it on first use.

## SYNTAX

### __AllParameterSets

```
Get-MyCredential [-CredPath] <string>
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Returns a PSCredential loaded from a CLIXML file at the given path.
If the
file does not exist, prompts for a credential (Get-Credential) and saves it
there first via Export-Credential.

## EXAMPLES

### EXAMPLE 1

$cred = Get-MyCredential -CredPath C:\creds\svc.xml

## PARAMETERS

### -CredPath

Path to the credential CLIXML file.

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

### CommonParameters

This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable,
-InformationAction, -InformationVariable, -OutBuffer, -OutVariable, -PipelineVariable,
-ProgressAction, -Verbose, -WarningAction, and -WarningVariable. For more information, see
[about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.PSCredential

{{ Fill in the Description }}

## NOTES

The stored password is DPAPI-protected: it can only be decrypted by the same
Windows user on the same machine that created the file.


## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/Get-MyCredential.html)
