function Get-VMInfoLive {
    <#
    .SYNOPSIS
        (Private) Runs the real, live multi-platform VM query.

    .DESCRIPTION
        Queries every connected vCenter, Prism Central, and mounted Hyper-V host
        for VMs matching the selection criteria, normalizes all platforms into a
        single object shape, and returns one uniform collection -- including the
        reverse-DNS fallback for rows without a DnsName. This is the slow path:
        several per-VM round trips per platform (tags, snapshots, datastores,
        disks, network adapters).

        Shared by Get-VMInfo (-Live, or when no cache is available) and
        Update-VMInfoCache (which persists this output so Get-VMInfo's default
        reads don't have to pay this cost every time).
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('ByName', 'ByIPExact', 'ByIPLike')]
        [string]$Mode = 'ByName',

        [string]$VM = $env:COMPUTERNAME,
        [string]$IPExact,
        [string]$IPLike,

        [ValidateSet('All', 'Both', 'VMware', 'Nutanix', 'HyperV')]
        [string]$Platform = 'All',

        [switch]$NoResolveDns
    )

    # --- Common output shape -------------------------------------------------
    # Every platform mapper returns this exact property set so the formatter
    # builds one consistent table. Platform-specific fields are $null when N/A.
    function New-VMInfoObject {
        param([hashtable]$Values)
        $obj = [PSCustomObject]@{
            Platform           = $null
            Name               = $null
            DnsName            = $null
            Notes              = $null
            OS                 = $null
            NumCpu             = $null
            MemoryGB           = $null
            IPAddresses        = $null
            Tags               = $null
            PowerState         = $null
            VMHost             = $null
            Cluster            = $null
            CreateDate         = $null
            PersistentId       = $null
            ClusterRule        = $null
            Source             = $null   # vCenter / Prism Central name
            OldestSnapshot     = $null
            Datastore          = $null
            Folder             = $null
            UsedSpaceGB        = $null
            ProvisionedSpaceGB = $null
            HardwareVersion    = $null
        }
        foreach ($k in $Values.Keys) { $obj.$k = $Values[$k] }

        # Default columns shown when the object is displayed without an explicit
        # Select/Format. All other properties remain available (Select *, Format-List).
        $defaultDisplay = 'Name', 'DnsName', 'IPAddresses', 'Notes'
        $propSet = New-Object System.Management.Automation.PSPropertySet(
            'DefaultDisplayPropertySet', [string[]]$defaultDisplay)
        $obj | Add-Member -MemberType MemberSet -Name PSStandardMembers `
            -Value ([System.Management.Automation.PSMemberInfo[]]@($propSet))
        $obj
    }

    # --- VMware --------------------------------------------------------------
    function Get-VMwareVMInfo {
        # Select VMs per the active parameter set. Name filters at the source
        # (fast); IP filters must enumerate then test the guest IP list.
        param([string]$Mode, [string]$VM, [string]$IPExact, [string]$IPLike)
        $vms = switch ($Mode) {
            'ByName'    { VMware.VimAutomation.Core\Get-VM "*$VM*" }
            'ByIPExact' { VMware.VimAutomation.Core\Get-VM | Where-Object { $_.Guest.IPAddress -contains $IPExact } }
            'ByIPLike'  { VMware.VimAutomation.Core\Get-VM | Where-Object { $_.Guest.IPAddress -like "*$IPLike*" } }
        }
        $vms | ForEach-Object {
            $v = $_
            New-VMInfoObject @{
                Platform           = 'VMware'
                Name               = $v.Name
                DnsName            = $v.ExtensionData.Guest.Hostname
                Notes              = $v.Notes
                OS                 = $v.Guest.OSFullName
                NumCpu             = $v.NumCpu
                MemoryGB           = $v.MemoryGB
                IPAddresses        = $v.Guest.IPAddress -join ', '
                Tags               = ($v | Get-TagAssignment).Tag
                PowerState         = $v.PowerState
                VMHost             = $v.VMHost
                Cluster            = (VMware.VimAutomation.Core\Get-VMHost $v.VMHost).Parent
                CreateDate         = $v.CreateDate
                PersistentId       = $v.PersistentId
                ClusterRule        = (Get-DrsClusterGroup -VM $v).Name
                Source             = ($v.Uid.Split('@')[1]).Split('.')[0]
                OldestSnapshot     = (Get-Snapshot -VM $v | Sort-Object Created | Select-Object -First 1).Created
                Datastore          = (Get-Datastore -Id $v.DatastoreIdList).Name
                Folder             = $v.Folder.Name
                UsedSpaceGB        = [math]::Round($v.UsedSpaceGB, 2)
                ProvisionedSpaceGB = [math]::Round(($v | Get-HardDisk | Measure-Object -Property CapacityGB -Sum).Sum, 2)
                HardwareVersion    = $v.HardwareVersion
            }
        }
    }

    # --- Nutanix -------------------------------------------------------------
    function Get-NutanixVMInfo {
        param([string]$Mode, [string]$VM, [string]$IPExact, [string]$IPLike)
        $vms = Nutanix.Prism.PS.Cmds\Get-VM | Where-Object {
            $i = $_   # capture: switch below rebinds $_ to its own input
            switch ($Mode) {
                'ByName'    { $i.vmName -match "(?i)$VM" }
                'ByIPExact' { $i.ipAddresses -contains $IPExact }
                'ByIPLike'  { ($i.ipAddresses -join ',') -like "*$IPLike*" }
            }
        }
        $vms | ForEach-Object {
            $v = $_
            New-VMInfoObject @{
                Platform           = 'Nutanix'
                Name               = $v.vmName
                Notes              = $v.description
                OS                 = $v.guestOperatingSystem   # empty on AHV without guest tools
                NumCpu             = $v.numVCpus
                MemoryGB           = [math]::Round($v.memoryCapacityInBytes / 1GB, 2)
                IPAddresses        = $v.ipAddresses -join ', '
                PowerState         = $v.powerState
                VMHost             = $v.hostName
                Cluster            = $v.clusterUuid           # no friendly cluster name exposed
                PersistentId       = $v.vmId
                Source             = $v.pcHostName            # Prism Central / Element host
                ProvisionedSpaceGB = [math]::Round($v.diskCapacityInBytes / 1GB, 2)
            }
        }
    }

    # --- Hyper-V -------------------------------------------------------------
    # No ambient connection: iterate the CIM sessions mounted by Connect-HyperVHost.
    # Guest IPs / DNS / OS aren't on the VM object -- IPs come from the network
    # adapters (also used to satisfy the IP parameter sets); DnsName is left for
    # the reverse-DNS fallback below. Clustered VMs can surface on more than one
    # node, so dedupe by VMId.
    function Get-HyperVVMInfo {
        param([string]$Mode, [string]$VM, [string]$IPExact, [string]$IPLike)

        if ($script:HyperVSessions.Count -eq 0) {
            Write-Warning "No Hyper-V hosts connected. Run Connect-HyperVHost (or set HyperVHosts via Set-AdminConfig) first."
            return
        }

        $seen = [System.Collections.Generic.HashSet[string]]::new()

        foreach ($session in $script:HyperVSessions.Values) {
            $vms = $null
            try {
                $vms = if ($Mode -eq 'ByName') {
                    Hyper-V\Get-VM -CimSession $session -Name "*$VM*" -ErrorAction SilentlyContinue
                } else {
                    Hyper-V\Get-VM -CimSession $session -ErrorAction SilentlyContinue
                }
            } catch {
                Write-Warning "Failed to query Hyper-V host '$($session.ComputerName)': $_"
                continue
            }

            foreach ($v in $vms) {
                # Dedupe clustered VMs owned by whichever node we hit first.
                if (-not $seen.Add([string]$v.VMId)) { continue }

                # Guest IPs from the VM's network adapters (best-effort).
                $ips = @()
                try {
                    $ips = @($v | Hyper-V\Get-VMNetworkAdapter -ErrorAction Stop |
                        ForEach-Object { $_.IPAddresses } | Where-Object { $_ })
                } catch { $ips = @() }

                # Apply IP parameter-set filters. (Use a value, not 'continue'
                # inside switch -- 'continue' there breaks the switch, not the loop.)
                $include = switch ($Mode) {
                    'ByIPExact' { $ips -contains $IPExact }
                    'ByIPLike'  { ($ips -join ',') -like "*$IPLike*" }
                    default     { $true }
                }
                if (-not $include) { continue }

                # Oldest checkpoint and disk sizing are best-effort (extra remote calls).
                $oldestSnap = $null
                try {
                    $oldestSnap = ($v | Hyper-V\Get-VMSnapshot -ErrorAction Stop |
                        Sort-Object CreationTime | Select-Object -First 1).CreationTime
                } catch { $oldestSnap = $null }

                $used = $null; $provisioned = $null
                try {
                    $vhds = $v | Hyper-V\Get-VMHardDiskDrive -ErrorAction Stop |
                        ForEach-Object { Hyper-V\Get-VHD -CimSession $session -Path $_.Path -ErrorAction Stop }
                    if ($vhds) {
                        $used        = [math]::Round((($vhds | Measure-Object -Property FileSize -Sum).Sum) / 1GB, 2)
                        $provisioned = [math]::Round((($vhds | Measure-Object -Property Size     -Sum).Sum) / 1GB, 2)
                    }
                } catch { $used = $null; $provisioned = $null }

                New-VMInfoObject @{
                    Platform           = 'HyperV'
                    Name               = $v.Name
                    Notes              = $v.Notes
                    NumCpu             = $v.ProcessorCount
                    MemoryGB           = [math]::Round($v.MemoryStartup / 1GB, 2)
                    IPAddresses        = $ips -join ', '
                    PowerState         = $v.State
                    VMHost             = $v.ComputerName
                    CreateDate         = $v.CreationTime
                    PersistentId       = $v.VMId
                    Source             = $v.ComputerName          # the Hyper-V host
                    OldestSnapshot     = $oldestSnap
                    UsedSpaceGB        = $used
                    ProvisionedSpaceGB = $provisioned
                    HardwareVersion    = $v.Version               # VM config version
                }
            }
        }
    }

    # --- Dispatch --------------------------------------------------------------
    $all = $Platform -in 'All', 'Both'   # 'Both' kept as a back-compat synonym
    $results = @()
    if ($all -or $Platform -eq 'VMware')  { $results += Get-VMwareVMInfo  -Mode $Mode -VM $VM -IPExact $IPExact -IPLike $IPLike }
    if ($all -or $Platform -eq 'Nutanix') { $results += Get-NutanixVMInfo -Mode $Mode -VM $VM -IPExact $IPExact -IPLike $IPLike }
    if ($all -or $Platform -eq 'HyperV')  { $results += Get-HyperVVMInfo  -Mode $Mode -VM $VM -IPExact $IPExact -IPLike $IPLike }

    # Fall back to reverse DNS for rows the hypervisor couldn't supply a name
    # for. -QuickTimeout keeps missing PTR records from stalling bulk queries.
    if (-not $NoResolveDns) {
        foreach ($r in $results) {
            if (-not [string]::IsNullOrWhiteSpace($r.DnsName)) { continue }
            $firstIp = ($r.IPAddresses -split ',' | Select-Object -First 1).Trim()
            if (-not $firstIp) { continue }
            $ptr = Resolve-DnsName -Name $firstIp -Type PTR -QuickTimeout -ErrorAction SilentlyContinue |
                Select-Object -First 1 -ExpandProperty NameHost -ErrorAction SilentlyContinue
            if ($ptr) { $r.DnsName = $ptr }
        }
    }

    $results | Sort-Object Platform, Name
}
