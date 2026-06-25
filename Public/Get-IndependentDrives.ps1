function Get-IndependentDrives {
    <#
    .SYNOPSIS
        Lists Independent Persistent virtual disks on powered-on VMware VMs.

    .DESCRIPTION
        Scans all VMware VMs for hard disks in Independent Persistent persistence
        mode on VMs that are powered on, and reports the VM name, the matching disk
        name(s), and the source vCenter. Requires a VMware PowerCLI connection
        (Connect-VIServer).

    .EXAMPLE
        Get-IndependentDrives

    .OUTPUTS
        PSCustomObject (Name, 'HD Name', vCenter).
    #>
    [CmdletBinding()]
    param()

    VMware.VimAutomation.Core\Get-VM |
        Where-Object {
            ($_.PowerState -eq 'PoweredOn') -and
            ($_ | Get-HardDisk | Where-Object { $_.Persistence -like 'IndependentP*' })
        } |
        Select-Object Name,
            @{N = 'HD Name'; E = { ($_ | Get-HardDisk | Where-Object { $_.Persistence -like 'IndependentP*' }).Name }},
            @{N = 'vCenter'; E = { $_.Uid.Split('@')[1].Split('.')[0] }} |
        Sort-Object vCenter, Name
}
