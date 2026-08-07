---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: New-IsoFile
---

# New-IsoFile

## SYNOPSIS

Creates a new .iso file.

## SYNTAX

### Source (Default)

```
New-IsoFile [-Source] <Object> [[-Path] <string>] [-BootFile <string>] [-Media <string>]
 [-Title <string>] [-Force]
```

### Clipboard

```
New-IsoFile [[-Path] <string>] [-BootFile <string>] [-Media <string>] [-Title <string>] [-Force]
 [-FromClipboard]
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

The New-IsoFile cmdlet creates a new .iso file containing content from
chosen folders.

## EXAMPLES

### EXAMPLE 1

New-IsoFile "c:\tools","c:\Downloads\utils"
Creates a .iso file in the $env:temp folder (default location) that contains
the c:\tools and c:\Downloads\utils folders. The folders themselves are
included at the root of the .iso image.

### EXAMPLE 2

New-IsoFile -FromClipboard -Verbose
Before running this command, select and copy (Ctrl-C) files/folders in
Explorer first.

### EXAMPLE 3

dir c:\WinPE | New-IsoFile -Path c:\temp\WinPE.iso -BootFile "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\efisys.bin" -Media DVDPLUSR -Title "WinPE"
Creates a bootable .iso file containing the content from the c:\WinPE folder,
but the folder itself isn't included. Boot file etfsboot.com can be found in
the Windows ADK. Refer to the IMAPI_MEDIA_PHYSICAL_TYPE enumeration for
possible media types:
http://msdn.microsoft.com/en-us/library/windows/desktop/aa366217(v=vs.85).aspx

## PARAMETERS

### -BootFile

{{ Fill BootFile Description }}

```yaml
Type: System.String
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

### -Force

{{ Fill Force Description }}

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

### -FromClipboard

{{ Fill FromClipboard Description }}

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Clipboard
  Position: Named
  IsRequired: false
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Media

{{ Fill Media Description }}

```yaml
Type: System.String
DefaultValue: DVDPLUSRW_DUALLAYER
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

{{ Fill Path Description }}

```yaml
Type: System.String
DefaultValue: "\"$env:temp\\$((Get-Date).ToString('yyyyMMdd-HHmmss.ffff')).iso\""
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

### -Source

{{ Fill Source Description }}

```yaml
Type: System.Object
DefaultValue: ''
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: Source
  Position: 1
  IsRequired: true
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -Title

{{ Fill Title Description }}

```yaml
Type: System.String
DefaultValue: (Get-Date).ToString("yyyyMMdd-HHmmss.ffff")
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

### System.Object

{{ Fill in the Description }}

## OUTPUTS

## NOTES

NAME:    New-IsoFile
AUTHOR:  Chris Wu
LASTEDIT: 03/23/2016 14:46:50


## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/New-IsoFile.html)
