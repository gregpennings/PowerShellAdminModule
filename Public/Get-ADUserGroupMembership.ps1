function Get-ADUserGroupMembership {
    <#
    .SYNOPSIS
        Lists the AD groups a user is a direct member of.

    .DESCRIPTION
        Returns the names of the Active Directory groups the specified user belongs
        to (direct membership, from the user's MemberOf), sorted by name.

    .PARAMETER UserName
        SamAccountName of the user. Defaults to the current user. Accepts pipeline input.

    .EXAMPLE
        Get-ADUserGroupMembership -UserName jdoe

    .EXAMPLE
        'jdoe' | Get-ADUserGroupMembership

    .OUTPUTS
        Microsoft.ActiveDirectory.Management.ADGroup (Name).
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$UserName = $env:USERNAME
    )
    process {
        (Get-ADUser -Identity $UserName -Properties MemberOf).MemberOf |
            Get-ADGroup |
            Sort-Object Name |
            Select-Object Name
    }
}
