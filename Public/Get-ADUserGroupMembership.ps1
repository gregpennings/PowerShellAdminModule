function Get-ADUserGroupMembership {
    <#
    .SYNOPSIS
        Lists the AD groups a user is a direct member of.

    .DESCRIPTION
        Returns the names of the Active Directory groups the specified user belongs
        to (direct membership, from the user's MemberOf), sorted by name.

        With -GridView, all enabled users are shown in a grid first; the groups of
        the user you select are returned. This replaces the former
        Get-ADUserGroupMembership_OGV function.

    .PARAMETER UserName
        SamAccountName of the user. Defaults to the current user. Accepts pipeline input.

    .PARAMETER GridView
        Show all enabled AD users in a grid view and return the group memberships of
        the user selected. Ignores -UserName.

    .EXAMPLE
        Get-ADUserGroupMembership -UserName jdoe

    .EXAMPLE
        Get-ADUserGroupMembership jdoe
        Positional form -- lists jdoe's groups (sorted by name). Quote names that
        contain spaces, e.g. Get-ADUserGroupMembership 'g-citrix admins'.

    .EXAMPLE
        Get-ADUserGroupMembership jdoe | Out-String -Stream | Select-String sql
        Checks whether jdoe is in any group whose name matches "sql" -- a quick
        way to confirm a specific entitlement.

    .EXAMPLE
        'jdoe' | Get-ADUserGroupMembership

    .EXAMPLE
        Get-ADUserGroupMembership -GridView

    .OUTPUTS
        Microsoft.ActiveDirectory.Management.ADGroup (Name).
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(ParameterSetName = 'ByName', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$UserName = $env:USERNAME,

        [Parameter(ParameterSetName = 'GridView', Mandatory)]
        [switch]$GridView
    )
    process {
        if ($GridView) {
            $selected = Get-ADUser -Filter "Enabled -eq 'True'" -Properties SamAccountName, MemberOf |
                Select-Object Name, UserPrincipalName, SamAccountName, MemberOf |
                Sort-Object UserPrincipalName |
                Out-GridView -Title 'Select a user' -PassThru
            if (-not $selected) { return }
            $memberOf = $selected.MemberOf
        } else {
            $memberOf = (Get-ADUser -Identity $UserName -Properties MemberOf).MemberOf
        }

        $memberOf |
            Get-ADGroup |
            Sort-Object Name |
            Select-Object Name
    }
}
