function Get-VMInfoAllVMs {
    <#
    .SYNOPSIS
        Returns inventory information for all VMs across VMware and/or Nutanix.

    .DESCRIPTION
        Queries all VMs and returns their inventory details as objects. By default
        both VMware (vSphere) and Nutanix (Prism) are queried, and the objects are
        emitted to the pipeline so you can sort, filter, format, or export them.

        Use -ExportCsv to write the results to timestamped CSV file(s) instead --
        one file per platform, named via New-FileNameWithTimestamp. In that mode the
        function returns the file path(s) rather than the VM objects.

    .PARAMETER Platform
        Which platform(s) to query: VMware, Nutanix, or Both (default).

    .PARAMETER ExportCsv
        Write results to CSV file(s) and return the path(s) instead of the VM
        objects. One file per platform queried.

    .PARAMETER Path
        Output directory for the CSV file(s) when -ExportCsv is used. Defaults to
        C:\temp (created if it does not exist).

    .EXAMPLE
        Get-VMInfoAllVMs
        Returns all VMware and Nutanix VM objects to the pipeline.

    .EXAMPLE
        Get-VMInfoAllVMs -Platform VMware | Where-Object PowerState -eq 'PoweredOn'
        Returns only VMware VMs, filtered to those powered on.

    .EXAMPLE
        Get-VMInfoAllVMs -ExportCsv
        Writes C:\temp\<timestamp>.AllVMwareVMInfo.csv and <timestamp>.AllNutanixVMInfo.csv,
        and returns the two file paths.

    .NOTES
        Replaces the former Get-VMInfoAllVMs_CSV (which always exported to C:\temp).
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('VMware', 'Nutanix', 'Both')]
        [string]$Platform = 'Both',

        [switch]$ExportCsv,

        [string]$Path = $script:AdminConfig.DefaultExportPath
    )

    $exported = @()

    if ($Platform -in 'VMware', 'Both') {
        $vmware = VMware.VimAutomation.Core\Get-VM | Select-Object Name,
            @{N = "DnsName";            E = { $psitem.ExtensionData.Guest.Hostname }},
            @{N = "Notes";              E = { $psitem.Notes }},
            @{N = "OS";                 E = { $psitem.Guest.OSFullName }},
            NumCpu, MemoryGB,
            @{N = "IPAddresses";        E = { $psitem.Guest.IPAddress }},
            @{N = "Tags";               E = { ($psitem | Get-TagAssignment).Tag }},
            PowerState, VMHost,
            @{N = "Cluster";            E = { (VMware.VimAutomation.Core\Get-VMHost $psitem.VMHost).Parent }},
            CreateDate, PersistentId,
            @{N = "ClusterRule";        E = { (Get-DrsClusterGroup -VM $psitem).Name }},
            @{N = "vCenter";            E = { ($psitem.Uid.Split("@")[1]).Split(".")[0] }},
            @{N = "Oldest Snapshot";    E = { (Get-Snapshot -VM $psitem | Sort-Object Created | Select-Object -First 1).Created }},
            @{N = "Datastore";          E = { (Get-Datastore -Id $psitem.DatastoreIdList).Name }},
            @{N = "Folder";             E = { $psitem.Folder.Name }},
            @{N = "UsedSpaceGB";        E = { [math]::round($psitem.UsedSpaceGB, 2) }},
            @{N = "ProvisionedSpaceGB"; E = { [math]::round(($psitem | Get-HardDisk | Measure-Object -Property CapacityGB -Sum).Sum, 2) }},
            HardwareVersion

        if ($ExportCsv) {
            $file = New-FileNameWithTimestamp -Subject 'AllVMwareVMInfo' -Extension csv -Path $Path -IncludeSeconds
            $vmware | Export-Csv -Path $file.FullName -NoTypeInformation
            $exported += $file.FullName
        } else {
            $vmware
        }
    }

    if ($Platform -in 'Nutanix', 'Both') {
        $nutanix = nutanix.Prism.PS.Cmds\Get-VM | Select-Object vmname, dnsname, description,
            numVCpus, memoryCapacityInBytes, ipaddresses, powerstate, hostName, vmId,
            nutanixVirtualDisks, diskCapacityInBytes

        if ($ExportCsv) {
            $file = New-FileNameWithTimestamp -Subject 'AllNutanixVMInfo' -Extension csv -Path $Path -IncludeSeconds
            $nutanix | Export-Csv -Path $file.FullName -NoTypeInformation
            $exported += $file.FullName
        } else {
            $nutanix
        }
    }

    if ($ExportCsv) {
        Write-Verbose "Exported $($exported.Count) file(s) to $Path"
        $exported
    }
}
