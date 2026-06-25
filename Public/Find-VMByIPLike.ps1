Function Find-VMByIPLike {
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
		[Parameter(mandatory)][string]$IP = $env:computername
			) #End param
	VMware.VimAutomation.Core\get-vm | where {$_.guest.IPAddress -like "*$IP*"} | select name,@{N="DnsName"; E={$_.ExtensionData.Guest.Hostname}},@{n="Notes";e={$psitem | select -ExpandProperty notes}},@{n="OS";e={$psitem.guest.OSFullName}},@{N="IPAddresses";E={@($_.guest.IPAddress)}},@{n="Tags";e={($psitem | Get-TagAssignment).tag}},powerstate,VMHost,CreateDate,persistentid,@{n="ClusterRule";e={(get-drsclustergroup -vm $psitem).name}},@{n="vCenter";e={(((($psitem.uid).split("@"))[1]).split("."))[0]}}

	nutanix.Prism.PS.Cmds\get-vm | Where-Object { $psitem.ipaddresses -like "*$IP*" } | Select vmname,dnsname,description,numVCpus,memoryCapacityInBytes,ipaddresses,powerstate,hostName,vmId,nutanixVirtualDisks,diskCapacityInBytes
}
