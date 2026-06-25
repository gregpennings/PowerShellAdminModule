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

    .OUTPUTS
        PSCustomObject with a common set of properties across platforms,
        including a Platform column indicating the source. Default display
        columns: Name, Notes, OS, IPAddresses.

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

        [ValidateSet('Both', 'VMware', 'Nutanix')][string]$Platform = 'Both'
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
        $defaultDisplay = 'Name', 'Notes', 'OS', 'IPAddresses'
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
        $vms = switch ($PSCmdlet.ParameterSetName) {
            'ByName'    { VMware.VimAutomation.Core\Get-VM "*$VM*" }
            'ByIPExact' { VMware.VimAutomation.Core\Get-VM | Where-Object { $_.Guest.IPAddress -contains $IPExact } }
            'ByIPLike'  { VMware.VimAutomation.Core\Get-VM | Where-Object { $_.Guest.IPAddress -like "*$IPLike*" } }
        }
        $vms | ForEach-Object {
            $vm = $_
            New-VMInfoObject @{
                Platform           = 'VMware'
                Name               = $vm.Name
                DnsName            = $vm.ExtensionData.Guest.Hostname
                Notes              = $vm.Notes
                OS                 = $vm.Guest.OSFullName
                NumCpu             = $vm.NumCpu
                MemoryGB           = $vm.MemoryGB
                IPAddresses        = $vm.Guest.IPAddress
                Tags               = ($vm | Get-TagAssignment).Tag
                PowerState         = $vm.PowerState
                VMHost             = $vm.VMHost
                Cluster            = (VMware.VimAutomation.Core\Get-VMHost $vm.VMHost).Parent
                CreateDate         = $vm.CreateDate
                PersistentId       = $vm.PersistentId
                ClusterRule        = (Get-DrsClusterGroup -VM $vm).Name
                Source             = ($vm.Uid.Split('@')[1]).Split('.')[0]
                OldestSnapshot     = (Get-Snapshot -VM $vm | Sort-Object Created | Select-Object -First 1).Created
                Datastore          = (Get-Datastore -Id $vm.DatastoreIdList).Name
                Folder             = $vm.Folder.Name
                UsedSpaceGB        = [math]::Round($vm.UsedSpaceGB, 2)
                ProvisionedSpaceGB = [math]::Round(($vm | Get-HardDisk | Measure-Object -Property CapacityGB -Sum).Sum, 2)
                HardwareVersion    = $vm.HardwareVersion
            }
        }
    }

    # --- Nutanix -------------------------------------------------------------
    function Get-NutanixVMInfo {
        $vms = Nutanix.Prism.PS.Cmds\Get-VM | Where-Object {
            switch ($PSCmdlet.ParameterSetName) {
                'ByName'    { $_.vmName -match "(?i)$VM" }
                'ByIPExact' { $_.ipAddresses -contains $IPExact }
                'ByIPLike'  { $_.ipAddresses -like "*$IPLike*" }
            }
        }
        $vms | ForEach-Object {
            $vm = $_
            New-VMInfoObject @{
                Platform           = 'Nutanix'
                Name               = $vm.vmName
                DnsName            = $vm.dnsName
                Notes              = $vm.description
                OS                 = $vm.operatingSystem   # often $null on AHV; left for parity
                NumCpu             = $vm.numVCpus
                MemoryGB           = [math]::Round($vm.memoryCapacityInBytes / 1GB, 2)
                IPAddresses        = $vm.ipAddresses
                PowerState         = $vm.powerState
                VMHost             = $vm.hostName
                Cluster            = $vm.clusterName
                PersistentId       = $vm.vmId
                Source             = $vm.clusterName       # Prism cluster the VM lives on
                ProvisionedSpaceGB = [math]::Round($vm.diskCapacityInBytes / 1GB, 2)
            }
        }
    }

    # --- Dispatch ------------------------------------------------------------
    $results = @()
    if ($Platform -in 'Both', 'VMware')  { $results += Get-VMwareVMInfo }
    if ($Platform -in 'Both', 'Nutanix') { $results += Get-NutanixVMInfo }

    $results | Sort-Object Platform, Name
}
