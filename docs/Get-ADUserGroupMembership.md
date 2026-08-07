---
document type: cmdlet
external help file: Admin-Help.xml
HelpUri: https://gregpennings.github.io/PowerShellAdminModule/
Locale: en-US
Module Name: Admin
ms.date: 08-07-2026
PlatyPS schema version: 2024-05-01
title: Get-ADUserGroupMembership
---

# Get-ADUserGroupMembership

## SYNOPSIS

Lists the AD groups a user is a direct member of.

## SYNTAX

### ByName (Default)

```
Get-ADUserGroupMembership [-UserName <string>]
```

### GridView

```
Get-ADUserGroupMembership -GridView
```

## ALIASES

This cmdlet has the following aliases,
  {{Insert list of aliases}}

## DESCRIPTION

Returns the names of the Active Directory groups the specified user belongs
to (direct membership, from the user's MemberOf), sorted by name.

With -GridView, all enabled users are shown in a grid first; the groups of
the user you select are returned.
This replaces the former
Get-ADUserGroupMembership_OGV function.

## EXAMPLES

### EXAMPLE 1

Get-ADUserGroupMembership -UserName jdoe

### EXAMPLE 2

Get-ADUserGroupMembership jdoe
Positional form -- lists jdoe's groups (sorted by name). Quote names that
contain spaces, e.g. Get-ADUserGroupMembership 'g-citrix admins'.

### EXAMPLE 3

Get-ADUserGroupMembership jdoe | Out-String -Stream | Select-String sql
Checks whether jdoe is in any group whose name matches "sql" -- a quick
way to confirm a specific entitlement.

### EXAMPLE 4

'jdoe' | Get-ADUserGroupMembership

### EXAMPLE 5

Get-ADUserGroupMembership -GridView

## PARAMETERS

### -GridView

Show all enabled AD users in a grid view and return the group memberships of
the user selected.
Ignores -UserName.

```yaml
Type: System.Management.Automation.SwitchParameter
DefaultValue: False
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: GridView
  Position: Named
  IsRequired: true
  ValueFromPipeline: false
  ValueFromPipelineByPropertyName: false
  ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: []
HelpMessage: ''
```

### -UserName

SamAccountName of the user.
Defaults to the current user.
Accepts pipeline input.

```yaml
Type: System.String
DefaultValue: $env:USERNAME
SupportsWildcards: false
Aliases: []
ParameterSets:
- Name: ByName
  Position: Named
  IsRequired: false
  ValueFromPipeline: true
  ValueFromPipelineByPropertyName: true
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

### System.String

{{ Fill in the Description }}

## OUTPUTS

### Microsoft.ActiveDirectory.Management.ADGroup (Name).

{{ Fill in the Description }}

## NOTES

## RELATED LINKS

- [](https://gregpennings.github.io/PowerShellAdminModule/Get-ADUserGroupMembership.html)
