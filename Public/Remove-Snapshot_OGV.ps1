function Remove-Snapshot_OGV {
    <#
    .SYNOPSIS
        Interactively selects and removes a VMware VM snapshot.

    .DESCRIPTION
        Lists every snapshot across all VMs (oldest first) in a grid view and removes
        the snapshot you select (asynchronously). Requires a VMware PowerCLI
        connection (Connect-VIServer).

    .EXAMPLE
        Remove-Snapshot_OGV

    .OUTPUTS
        None.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param()

    $selected = VMware.VimAutomation.Core\Get-VM | Get-Snapshot |
        Sort-Object Created |
        Select-Object VM, Name, Created, Id |
        Out-GridView -Title 'Select a snapshot to remove' -PassThru

    if (-not $selected) { return }

    if ($PSCmdlet.ShouldProcess("$($selected.Name) on $($selected.VM)", 'Remove snapshot')) {
        VMware.VimAutomation.Core\Get-VM $selected.VM.Name | Get-Snapshot |
            Where-Object { $_.Id -eq $selected.Id } |
            Remove-Snapshot -RunAsync -Confirm:$false
    }
}
