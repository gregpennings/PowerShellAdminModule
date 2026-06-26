function Get-VMInfoAllVMs {
    <#
    .SYNOPSIS
        Returns inventory information for all VMs across VMware, Nutanix, and/or Hyper-V.

    .DESCRIPTION
        Queries all VMs and returns their inventory details as objects. By default
        all platforms -- VMware (vSphere), Nutanix (Prism), and Hyper-V -- are
        queried, and the objects are emitted to the pipeline so you can sort, filter,
        format, or export them.

        Hyper-V is queried over the CIM sessions mounted by Connect-HyperVHost;
        clustered VMs are deduped by VM id. If no Hyper-V hosts are connected, the
        Hyper-V pass is skipped with a warning.

        Use -ExportCsv to write the results to timestamped CSV file(s) instead --
        one file per platform, named via New-FileNameWithTimestamp. In that mode the
        function returns the file path(s) rather than the VM objects.

    .PARAMETER Platform
        Which platform(s) to query: VMware, Nutanix, HyperV, or All (default).
        'Both' is accepted as a back-compat synonym for All.

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
        Writes one timestamped CSV per queried platform (AllVMwareVMInfo /
        AllNutanixVMInfo / AllHyperVVMInfo) and returns the file paths.

    .NOTES
        Replaces the former Get-VMInfoAllVMs_CSV (which always exported to C:\temp).
    #>
    [CmdletBinding()]
    param(
        # 'Both' retained as a back-compat synonym for 'All' (pre-Hyper-V default).
        [ValidateSet('VMware', 'Nutanix', 'HyperV', 'All', 'Both')]
        [string]$Platform = 'All',

        [switch]$ExportCsv,

        [string]$Path = $script:AdminConfig.DefaultExportPath
    )

    $exported = @()
    $all = $Platform -in 'All', 'Both'   # 'Both' kept as a back-compat synonym

    if ($all -or $Platform -eq 'VMware') {
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

    if ($all -or $Platform -eq 'Nutanix') {
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

    if ($all -or $Platform -eq 'HyperV') {
        if ($script:HyperVSessions.Count -eq 0) {
            Write-Warning "No Hyper-V hosts connected; skipping Hyper-V. Run Connect-HyperVHost first."
        } else {
            # Iterate each mounted host/node; dedupe clustered VMs by VMId. IPs come
            # from the network adapters (the VM object doesn't carry guest IPs).
            $seen = [System.Collections.Generic.HashSet[string]]::new()
            $hyperv = foreach ($session in $script:HyperVSessions.Values) {
                $vms = $null
                try {
                    $vms = Hyper-V\Get-VM -CimSession $session -ErrorAction SilentlyContinue
                } catch {
                    Write-Warning "Failed to query Hyper-V host '$($session.ComputerName)': $_"
                    continue
                }
                foreach ($v in $vms) {
                    if (-not $seen.Add([string]$v.VMId)) { continue }
                    $ips = @()
                    try {
                        $ips = @($v | Hyper-V\Get-VMNetworkAdapter -ErrorAction Stop |
                            ForEach-Object { $_.IPAddresses } | Where-Object { $_ })
                    } catch { $ips = @() }
                    [PSCustomObject]@{
                        Name                  = $v.Name
                        State                 = $v.State
                        ProcessorCount        = $v.ProcessorCount
                        MemoryStartupGB       = [math]::Round($v.MemoryStartup / 1GB, 2)
                        IPAddresses           = $ips -join ', '
                        VMHost                = $v.ComputerName
                        IsClustered           = $v.IsClustered
                        CreationTime          = $v.CreationTime
                        VMId                  = $v.VMId
                        ConfigurationVersion  = $v.Version
                        Notes                 = $v.Notes
                    }
                }
            }

            if ($ExportCsv) {
                $file = New-FileNameWithTimestamp -Subject 'AllHyperVVMInfo' -Extension csv -Path $Path -IncludeSeconds
                $hyperv | Export-Csv -Path $file.FullName -NoTypeInformation
                $exported += $file.FullName
            } else {
                $hyperv
            }
        }
    }

    if ($ExportCsv) {
        Write-Verbose "Exported $($exported.Count) file(s) to $Path"
        $exported
    }
}
