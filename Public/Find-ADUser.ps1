Function Find-ADUser {
<#
.SYNOPSIS
Finds enabled AD users matching a partial name, username, or display name.

.DESCRIPTION
Searches Active Directory for user objects using ANR (Ambiguous Name Resolution), excluding disabled accounts (UAC 1.2). Returns full [ADUser] objects with all properties loaded.

.PARAMETER SearchString
Enter part of the name, username, or display name to search for. This is a mandatory parameter and supports pipeline input.

.EXAMPLE
Find-ADUser "tim"
Returns all enabled AD users matching "tim" in name, username, or display name.

.EXAMPLE
"tim" | Find-ADUser
Demonstrates pipeline input.

.NOTES
Author: Greg Pennings
Supports -WhatIf and -Confirm via CmdletBinding.

.LINK
Get-ADUser
#>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([Microsoft.ActiveDirectory.Management.ADUser])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$SearchString
    )

    begin {
        # Standard Get-ADUser default display set. Applied so that loading -Properties *
        # still presents the familiar default table instead of dumping every attribute.
        $defaultDisplaySet = 'DistinguishedName', 'Enabled', 'GivenName', 'Name', 'ObjectClass', 'ObjectGUID', 'SamAccountName', 'SID', 'Surname', 'UserPrincipalName'
        $propertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet', [string[]]$defaultDisplaySet)
        $standardMembers = [System.Management.Automation.PSMemberInfo[]]@($propertySet)
    }

    process {
        if ($PSCmdlet.ShouldProcess($SearchString, "Search AD for matching users")) {
            Get-ADUser -LDAPFilter "(&(objectCategory=person)(objectClass=user)(!(userAccountControl:1.2.840.113556.1.4.803:=2))(anr=$SearchString))" -Properties * |
                ForEach-Object {
                    $_ | Add-Member -MemberType MemberSet -Name PSStandardMembers -Value $standardMembers -Force -PassThru
                }
        }
    }
}
