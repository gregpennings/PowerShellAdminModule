Function Get-VMInfo {
		    <#
    .SYNOPSIS
        Lists for VM info
		
	.PARAMETER Name
		VM Name to output info
		
    .OUTPUTS
        VM Name, DNS name, VM notes, OS, and IP Addresses

    #>
	[cmdletbinding()]
	param(  
		[Parameter(mandatory)][string]$VM = $env:computername
			) #End param
	VMware.VimAutomation.Core\get-vm *$VM* | select name,
	@{N="DnsName"; E={$psitem.ExtensionData.Guest.Hostname}},
	@{N="Notes"; E={$psitem.Notes}},
	@{N="OS"; E={$psitem.Guest.OSFullName}},
	NumCpu,MemoryGB,
	@{N="IPAddresses"; E={$psitem.Guest.IPAddress}},
	@{N="Tags"; E={($psitem | Get-TagAssignment).Tag}},
	PowerState, VMHost,
	@{N="Cluster"; E={(VMware.VimAutomation.Core\get-vmHost $psitem.VMHost).Parent}},
	CreateDate, PersistentId,
	@{N="ClusterRule"; E={(Get-DrsClusterGroup -VM $psitem).Name}},
	@{N="vCenter"; E={($psitem.Uid.Split("@")[1]).Split(".")[0]}},
	@{N="Oldest Snapshot"; E={(Get-Snapshot -VM $psitem | Sort-Object Created | Select-Object -First 1).Created}},
	@{N="Datastore"; E={(Get-Datastore -Id $psitem.DatastoreIdList).Name}},
	@{N="Folder"; E={$psitem.Folder.Name}},
    @{N="UsedSpaceGB"; E={[math]::round($psitem.UsedSpaceGB, 2)}},
    @{N="ProvisionedSpaceGB"; E={[math]::round(($psitem | Get-HardDisk | Measure-Object -Property CapacityGB -Sum).Sum, 2)}},
	HardwareVersion

	nutanix.Prism.PS.Cmds\get-vm | Where-Object { $psitem.vmName -match "(?i)$VM" } | Select vmname,dnsname,description,numVCpus,memoryCapacityInBytes,ipaddresses,powerstate,hostName,vmId,nutanixVirtualDisks,diskCapacityInBytes
}
