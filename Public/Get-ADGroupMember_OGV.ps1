function Get-ADGroupMember_OGV {
    <#
    .SYNOPSIS
        Interactively pick an AD group and list its members.

    .DESCRIPTION
        Shows all AD groups in a grid view; for the group you select, returns the
        member names and SamAccountNames, sorted by name.

    .EXAMPLE
        Get-ADGroupMember_OGV

    .OUTPUTS
        PSCustomObject (Name, SamAccountName).
    #>
    [CmdletBinding()]
    param()

    $group = Get-ADGroup -Filter * |
        Select-Object Name, SamAccountName |
        Out-GridView -Title 'Select a group' -PassThru

    Get-ADGroupMember -Identity $group.SamAccountName |
        Select-Object Name, SamAccountName |
        Sort-Object Name
}
