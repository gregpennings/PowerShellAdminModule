Function Get-VMInfo {
    <#
    .SYNOPSIS
        Lists VM info from VMware vCenter(s) and Nutanix Prism Central(s).

    .DESCRIPTION
        Queries every connected vCenter and Prism Central for VMs that match the
        selection criteria, normalizes both platforms into a single object shape,
        and returns one uniform collection. Assumes connections are already
        established (see profile: Connect-VIServer / Connect-PrismCentral).

        VMs can be selected by name (default), by exact IP, or by partial IP.

    .PARAMETER VM
        VM name (or substring) to match. Defaults to the local computer name.

    .PARAMETER IPExact
        Return VMs whose guest IP matches this address exactly.

    .PARAMETER IPLike
        Return VMs whose guest IP contains this substring (e.g. a subnet "10.1.2").

    .PARAMETER Platform
        Limit the query to one platform. Defaults to Both.

    .PARAMETER NoResolveDns
        Skip reverse-DNS resolution. By default, rows the hypervisor doesn't
        supply a DnsName for (Nutanix, or VMware without guest tools) have
        their first IP reverse-resolved to its registered network name; this
        adds one DNS lookup per such row, so pass -NoResolveDns on large sweeps.

    .OUTPUTS
        PSCustomObject with a common set of properties across platforms,
        including a Platform column indicating the source. Default display
        columns: Name, DnsName, IPAddresses, Notes.

    .EXAMPLE
        Get-VMInfo web01

    .EXAMPLE
        Get-VMInfo -IPExact 1.2.3.4

    .EXAMPLE
        Get-VMInfo -IPLike 10.1.2 -Platform Nutanix
    #>
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param(
        [Parameter(ParameterSetName = 'ByName', Position = 0)]
        [string]$VM = $env:COMPUTERNAME,

        [Parameter(ParameterSetName = 'ByIPExact', Mandatory)]
        [string]$IPExact,

        [Parameter(ParameterSetName = 'ByIPLike', Mandatory)]
        [string]$IPLike,

        [ValidateSet('Both', 'VMware', 'Nutanix')][string]$Platform = 'Both',

        # Reverse-resolve the first IP to its registered network name for rows
        # without a DnsName (Nutanix, or VMware without guest tools). On by
        # default; pass -NoResolveDns to skip the lookups on large sweeps.
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

    # --- Dispatch ------------------------------------------------------------
    # Pass the criteria explicitly: $PSCmdlet does not resolve inside nested
    # functions, so the parameter-set name must be handed in.
    $mode = $PSCmdlet.ParameterSetName
    $results = @()
    if ($Platform -in 'Both', 'VMware')  { $results += Get-VMwareVMInfo  -Mode $mode -VM $VM -IPExact $IPExact -IPLike $IPLike }
    if ($Platform -in 'Both', 'Nutanix') { $results += Get-NutanixVMInfo -Mode $mode -VM $VM -IPExact $IPExact -IPLike $IPLike }

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
