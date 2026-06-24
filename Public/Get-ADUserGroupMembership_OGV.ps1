function Get-ADUserGroupMembership_OGV {
    <#
    .SYNOPSIS
        Interactively pick an enabled AD user and list their group memberships.

    .DESCRIPTION
        Shows all enabled AD users in a grid view; for the user you select, returns
        the names of the groups they belong to, sorted by name.

    .EXAMPLE
        Get-ADUserGroupMembership_OGV

    .OUTPUTS
        Microsoft.ActiveDirectory.Management.ADGroup (Name).
    #>
    [CmdletBinding()]
    param()

    $selected = Get-ADUser -Filter "Enabled -eq 'True'" -Properties SamAccountName, MemberOf |
        Select-Object Name, UserPrincipalName, SamAccountName, MemberOf |
        Sort-Object UserPrincipalName |
        Out-GridView -Title 'Select a user' -PassThru

    $selected.MemberOf |
        Get-ADGroup |
        Select-Object Name |
        Sort-Object Name
}
