function Remove-VmAudioDevice_OGV {
    <#
    .SYNOPSIS
        Removes the virtual HD audio device from a selected VMware VM.

    .DESCRIPTION
        Finds all VMs that have a VirtualHdAudioCard, lets you pick one in a grid
        view, shuts the guest down if it is powered on, removes the audio device via
        a VirtualMachineConfigSpec reconfigure, then powers the VM back on. Requires
        a VMware PowerCLI connection.

    .EXAMPLE
        Remove-VmAudioDevice_OGV

    .OUTPUTS
        None.

    .NOTES
        Powers the selected VM off and back on -- use with care.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param()

    Write-Host "This will take a while. Be patient."

    $vmsWithAudio = foreach ($v in (VMware.VimAutomation.Core\Get-VM | Sort-Object Name)) {
        if ($v.ExtensionData.Config.Hardware.Device | Where-Object { $_.GetType().Name -eq 'VirtualHdAudioCard' }) {
            $v.Name
        }
    }

    $vmName = $vmsWithAudio | Out-GridView -Title 'Select a VM to remove its audio device' -PassThru
    if (-not $vmName) { return }
    if (-not $PSCmdlet.ShouldProcess($vmName, 'Power off, remove HD audio device, power on')) { return }

    try {
        $vm = VMware.VimAutomation.Core\Get-VM -Name $vmName -ErrorAction Stop
        switch ($vm.PowerState) {
            'PoweredOn' {
                Shutdown-VMGuest -VM $vm -Confirm:$false
                while ($vm.PowerState -eq 'PoweredOn') {
                    Start-Sleep -Seconds 5
                    $vm = VMware.VimAutomation.Core\Get-VM -Name $vmName
                }
            }
            Default { Write-Host "VM '$vmName' is not powered on." }
        }
        Write-Host "$vmName has shut down. It should be ready for configuration."
    } catch {
        Write-Host "VM '$vmName' not found!"
        return
    }

    $audio = $vm.ExtensionData.Config.Hardware.Device | Where-Object { $_.GetType().Name -eq 'VirtualHdAudioCard' }

    $spec = New-Object VMware.Vim.VirtualMachineConfigSpec
    $dev  = New-Object VMware.Vim.VirtualDeviceConfigSpec
    $dev.Device    = $audio
    $dev.Operation = 'remove'
    $spec.deviceChange += $dev

    $vm.ExtensionData.ReconfigVM($spec)
    Start-VM $vmName
}
