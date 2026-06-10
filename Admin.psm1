#Admin Module
#Greg Pennings
#2020.08.12
#2021.03.22
#2021.08.17
#2021.12.29 - Test-Credential
#2022.05.16 - Get-IndependentDrives - changed to powered on and Independent Persistent only and added vCenter column
#2022.06.07 - New-ISOFile
#2022.07.11 - Get-VMInfo and Get-VMInfo_OGV
#2022.09.20 - Add get-vmhost to get-vminfo(s)
#2022.12.29 - Updated get-vminfo with cluster and vcenter info... and removed cluster group from info. Need more troubleshooting
#2023.01.20 - Added find VM by IP
#2023.02.xx - Added find VM by IP exact
#2023.07.21 - Added get-logged on user
#2024.03.01 - Added Cluster info to get-VMinfo
#2024.03.04 - Updated Find-VMinfo to new Get-VMinfo query
#2024.03.08 - Get Reboot History
#2024.06.05 - Add last snapshot to VMInfo
#2024.09.25 - Update all VMinfos
#2024.11.15 - Added Clear-LoggedOnSessions - Cleaner command with AI assistance
#2025.03.31 - Starting rewrite for Nutanix compatibility
#2025.04.01 - Adding Nutanix to VM commands - VM info
#2025.04.16 - Add Get-RemoteDiskUsage
#2025.04.28 - Add Get-SSLCertificateExpirationDate
#2025.07.17 - NewFileNameWithTimestamp and cleanup
#2025.09.04 - Find-FilesContainingText
#2025.10.02 - Fix Find-aduser 
#2025.10.09 - Add TransposeObject
#2026.04.09 - Add Get-WhoIs

function Get-Whois {
    [CmdletBinding()]
    param([Parameter(Mandatory, ValueFromPipeline)][string]$Domain)
    process {
        $tld = $Domain.Split('.')[-1]
        $services = (Invoke-RestMethod "https://data.iana.org/rdap/dns.json").services
        $rdapRoot = $services | Where-Object { $PSItem[0] -contains $tld } | Select-Object -First 1
        if (-not $rdapRoot) { throw "No RDAP server found for .$tld" }
        $r = Invoke-RestMethod "$($rdapRoot[1][0])domain/$Domain"

        $registrar = $r.entities | Where-Object { $PSItem.roles -contains 'registrar' } |
            Select-Object -First 1 -ExpandProperty vcardArray |
            Select-Object -Last 1 |
            ForEach-Object { $PSItem | Where-Object { $PSItem[0] -eq 'fn' } | ForEach-Object { $PSItem[3] } }

        $events = $r.events | Where-Object { $PSItem.eventAction -ne 'last update of RDAP database' } |
            ForEach-Object { "  $($PSItem.eventAction): $([datetime]$PSItem.eventDate | Get-Date -Format 'yyyy-MM-dd')" }

        $nameservers = $r.nameservers | ForEach-Object { "  $($PSItem.ldhName)" }

        [PSCustomObject]@{
            Domain      = $r.ldhName
            Status      = $r.status -join ', '
            Registrar   = $registrar
            NameServers = $nameservers -join "`n"
            Events      = $events -join "`n"
            DNSSEC      = $r.secureDNS.delegationSigned
        }
    }
}
Set-Alias -Name whois -Value Get-Whois

<#
.SYNOPSIS
Transpose properties of objects from columns to rows.
.DESCRIPTION
Transpose properties of objects from columns to rows. Useful when the order displayed in a GridView (with
Out-GridView) or in a CSV file (with Export-Csv) should be rotated.
It uses the name property or a given property as new property names (column headers) if it exists.
.PARAMETER Title
Name of property whose values are used as titles
.INPUTS
Object
.OUTPUTS
Transposed object
.EXAMPLE
dir | Transpose-Object | Out-GridView

Shows directory listing with a column instead of a row for every file/directory
.EXAMPLE
ps | Transpose-Object | Export-Csv Processes.csv -Delimiter ';' -NoTypeInformation

Creates a CSV file with a column instead of a row for every process
.NOTES
Name: Transpose-Object
Author: Markus Scholtes
Version: 1.2 - values of 0, $FALSE or "" not longer identified as $NULL
Creation Date: 20/03/2023
#>
function Transpose-Object
{ [CmdletBinding()]
  Param([OBJECT][Parameter(ValueFromPipeline = $TRUE)]$InputObject, [STRING]$Title = "Name")

  BEGIN
  { # initialize variables just to be "clean"
    $Props = @()
    $PropNames = @()
    $InstanceNames = @()
  }

  PROCESS
  {
  	if ($Props.Length -eq 0)
  	{ # when first object in pipeline arrives retrieve its property names
			$PropNames = $InputObject.PSObject.Properties | Select-Object -ExpandProperty Name
			# and create a PSCustomobject in an array for each property
			$InputObject.PSObject.Properties | %{ $Props += New-Object -TypeName PSObject -Property @{Property = $_.Name} }
		}

		if ([BOOL]($InputObject.psobject.Properties | where { $_.Name -eq $Title}))
 		{ # does object have a $Title property (default "Name")?
 			$Property = $InputObject.$Title
 		} else { # no, take object itself as property name
 			$Property = ($InputObject | Out-String).Trim()
		}

 		if ($InstanceNames -contains $Property)
 		{ # does multiple occurence of value of $Title exist?
  		$COUNTER = 0
  		$StoredValue = $Property
 			do { # yes, append a number in brackets to $Title
 				$COUNTER++
 				$Property = "$StoredValue ({0})" -f $COUNTER
 			} while ($InstanceNames -contains $Property)
 		}
 		# add current name to name list for next name check
 		$InstanceNames += $Property

  	# retrieve property values and add them to the property's PSCustomobject
  	$COUNTER = 0
  	$PropNames | %{
  		if ($NULL -ne $InputObject.($_))
  		{ # property exists for current object
  			$Props[$COUNTER] | Add-Member -Name $Property -Type NoteProperty -Value $InputObject.($_)
  		} else { # property does not exist for current object, add $NULL value
  			$Props[$COUNTER] | Add-Member -Name $Property -Type NoteProperty -Value $NULL
  		}
 			$COUNTER++
  	}
  }

  END
  {
  	# return collection of PSCustomobjects with property values
  	$Props
  }
}

<#
.SYNOPSIS
Searches recursively for files containing a specific text pattern.

.DESCRIPTION
This function searches all files under a specified path (defaulting to the current directory)
and returns the names of files that contain the given text pattern.

.PARAMETER Path
The root directory to begin the search. Defaults to the current directory.

.PARAMETER Pattern
The text string to search for within files. This parameter is mandatory.

.EXAMPLE
Find-FilesContainingText -Pattern "Execution Policy"

Searches the current directory and its subdirectories for files containing "Execution Policy".

.EXAMPLE
Find-FilesContainingText -Path "C:\GPOs" -Pattern "Execution Policy"

Searches under C:\GPOs for files containing "Execution Policy".

.NOTES
Author: Greg Pennings
Date: 2025-09-04
License: MIT
#>

function Find-FilesContainingText {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]$Path = ".",

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Pattern
    )

    Get-ChildItem -Path $Path -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { Select-String -Path $PSItem.FullName -Pattern $Pattern -Quiet } |
    Select-Object -ExpandProperty Name
}


<#
.SYNOPSIS
Generates a timestamped filename and returns it as a System.IO.FileInfo object.

.DESCRIPTION
Creates a filename in the format: yyyyMMddHHmm[ss].subject.extension.
Ensures the target directory exists. Optionally appends a numeric suffix if the file already exists.
Returns a FileInfo object for easy access to name, path, and full path.
Optionally creates an empty file at the generated path.

.PARAMETER Subject
The subject or label to include in the filename. Defaults to 'report'.

.PARAMETER Extension
The file extension to use. Defaults to 'csv'.

.PARAMETER Path
The directory where the file should be created. Defaults to 'C:\temp'.

.PARAMETER AppendIfExists
If specified, appends a numeric suffix (e.g., _1, _2) to avoid overwriting existing files.

.PARAMETER IncludeSeconds
If specified, includes seconds in the timestamp (format: yyyyMMddHHmmss).

.PARAMETER CreateEmptyFile
If specified, creates an empty file at the generated path.

.EXAMPLE
$file = New-FileNameWithTimestamp
$file.FullName

Generates a filename like C:\temp\202507171600.report.csv and returns it as a FileInfo object.

.EXAMPLE
Export-Csv -Path (New-FileNameWithTimestamp).FullName -NoTypeInformation

Exports data to a timestamped CSV file in C:\temp using the default subject and extension.

.EXAMPLE
New-FileNameWithTimestamp -Subject "SnapshotList" -Extension "log" -Path "D:\logs" -IncludeSeconds -Verbose

Generates a log filename with seconds included in the timestamp and outputs verbose details.

.EXAMPLE
New-FileNameWithTimestamp -AppendIfExists -CreateEmptyFile

Generates a unique filename in C:\temp, creates an empty file, and avoids overwriting existing files.

.NOTES
Author: You  
Module: Admin

.ERROR CODES
1001 - Failed to create or access the specified path.
1002 - Failed to generate a unique filename after multiple attempts.
1003 - Failed to create the empty file.
#>

function New-FileNameWithTimestamp {
    [CmdletBinding()]
    param (
        [string]$Subject = "report",
        [string]$Extension = "csv",
        [string]$Path = "C:\temp",
        [switch]$AppendIfExists,
        [switch]$IncludeSeconds,
        [switch]$CreateEmptyFile
    )

    Write-Verbose "Validating or creating path: $Path"
    if (-not (Test-Path $Path)) {
        try {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            Write-Verbose "Created directory: $Path"
        } catch {
            throw [System.Exception]::new("Error 1001: Failed to create or access path: $Path")
        }
    }

    $format = if ($IncludeSeconds) { "yyyyMMddHHmmss" } else { "yyyyMMddHHmm" }
    $timestamp = Get-Date -Format $format
    $baseName = "$timestamp.$Subject"
    $filename = "$baseName.$Extension"
    $fullPath = Join-Path -Path $Path -ChildPath $filename

    Write-Verbose "Generated base filename: $filename"

    if ($AppendIfExists -and (Test-Path $fullPath)) {
        Write-Verbose "File already exists. Attempting to append numeric suffix..."
        $counter = 1
        do {
            $filename = "$baseName" + "_$counter.$Extension"
            $fullPath = Join-Path -Path $Path -ChildPath $filename
            Write-Verbose "Trying: $filename"
            $counter++
            if ($counter -gt 100) {
                throw [System.Exception]::new("Error 1002: Failed to generate a unique filename after 100 attempts.")
            }
        } while (Test-Path $fullPath)
        Write-Verbose "Resolved unique filename: $filename"
    }

    if ($CreateEmptyFile) {
        try {
            Write-Verbose "Creating empty file at: $fullPath"
            New-Item -ItemType File -Path $fullPath -Force | Out-Null
        } catch {
            throw [System.Exception]::new("Error 1003: Failed to create the empty file at: $fullPath")
        }
    }

    return [System.IO.FileInfo]::new($fullPath)
}

function Get-SSLCertificateExpirationDate {
     param (
         [Parameter(Mandatory=$true)]
         [string]$url
     )

     try {
         # Create a TCP connection to the server
         $tcpClient = New-Object System.Net.Sockets.TcpClient
         $tcpClient.Connect($url, 443)

         # Create an SSL stream
         $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false, ({$true}))

         # Authenticate the SSL stream
         $sslStream.AuthenticateAsClient($url)

         # Get the certificate
         $cert = $sslStream.RemoteCertificate

         # Convert the certificate to an X509Certificate2 object
         $x509Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($cert)

         # Get the expiration date
         $expirationDate = $x509Cert.NotAfter

         # Close the connection
         $sslStream.Close()
         $tcpClient.Close()

         return $expirationDate
     } catch {
         Write-Error "Failed to retrieve SSL certificate expiration date for $url"
     }
 }

function Get-RemoteDiskUsage {
<#
.SYNOPSIS
    Retrieves disk usage information from a remote computer.

.DESCRIPTION
    This script connects to a specified remote computer and retrieves disk usage information for all file system drives. It displays the drive size, space used, space free, and percentage of space used and free.

.PARAMETER ComputerName
    The name of the remote computer from which to retrieve disk usage information.

.EXAMPLE
    Get-RemoteDiskUsage -ComputerName "Server01"
    Retrieves disk usage information from the remote computer named "Server01".

.NOTES
    Author: Greg Pennings (ChatGPT)
    Date: 2025-04-16
    Version: 1.0
#>

    param (
        [string[]]$ComputerName
    )
    
    # Ensure the computer name is provided
    if (-not $ComputerName) {
        Write-Error "ComputerName parameter is required."
        return
    }

    # Use Try-Catch to handle potential errors gracefully
    try {
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            Get-PSDrive -PSProvider FileSystem | Select-Object Name,
                @{Name="Drive Size (GB)";Expression={[math]::round(($_.Used + $_.Free) / 1GB, 2)}},
                @{Name="Space Used (GB)";Expression={[math]::round($_.Used / 1GB, 2)}},
                @{Name="% Used";Expression={"$([math]::round(($_.Used / ($_.Used + $_.Free)) * 100, 2))%"}},
                @{Name="Space Free (GB)";Expression={[math]::round($_.Free / 1GB, 2)}},
                @{Name="% Free";Expression={"$([math]::round(($_.Free / ($_.Used + $_.Free)) * 100, 2))%"}}
        } # | Select-Object @{N="Host";e={$psitem.PSComputerName}}, Name, "Drive Size (GB)","Space Used (GB)","Space Free (GB)","% Free"
    }
    catch {
        Write-Error "Failed to retrieve disk usage information: $_"
    }
}

Function Get-RebootHistory {
<#
.SYNOPSIS
    This will output who initiated a reboot or shutdown event.
 
.NOTES
    Name: Get-RebootHistory
    Author: theSysadminChannel
    Version: 1.0
    DateCreated: 2020-Aug-5
 
.LINK
    https://thesysadminchannel.com/get-reboot-history-using-powershell -
 
.EXAMPLE
    Get-RebootHistory -ComputerName Server01, Server02
 
.EXAMPLE
    Get-RebootHistory -DaysFromToday 30 -MaxEvents 1
 
.PARAMETER ComputerName
    Specify a computer name you would like to check.  The default is the local computer
 
.PARAMETER DaysFromToday
    Specify the amount of days in the past you would like to search for
 
.PARAMETER MaxEvents
    Specify the number of events you would like to search for (from newest to oldest)
#>
 
 
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string[]]  $ComputerName = $env:COMPUTERNAME,
 
        [int]       $DaysFromToday = 7,
 
        [int]       $MaxEvents = 9999
    )
 
    BEGIN {}
 
    PROCESS {
        foreach ($Computer in $ComputerName) {
            try {
                $Computer = $Computer.ToUpper()
                $EventList = Get-WinEvent -ComputerName $Computer -FilterHashtable @{
                    Logname = 'system'
                    Id = '1074', '6008'
                    StartTime = (Get-Date).AddDays(-$DaysFromToday)
                } -MaxEvents $MaxEvents -ErrorAction Stop
 
 
                foreach ($Event in $EventList) {
                    if ($Event.Id -eq 1074) {
                        [PSCustomObject]@{
                            TimeStamp    = $Event.TimeCreated
                            ComputerName = $Computer
                            UserName     = $Event.Properties.value[6]
                            ShutdownType = $Event.Properties.value[4]
                        }
                    }
 
                    if ($Event.Id -eq 6008) {
                        [PSCustomObject]@{
                            TimeStamp    = $Event.TimeCreated
                            ComputerName = $Computer
                            UserName     = $null
                            ShutdownType = 'unexpected shutdown'
                        }
                    }
 
                }
 
            } catch {
                Write-Error $_.Exception.Message
 
            }
        }
    }
 
    END {}
}

function Get-LoggedOnUser {
     [CmdletBinding()]
     param
     (
         [Parameter()]
         #[ValidateScript({ Test-Connection -ComputerName $_ -Quiet -Count 1 })]
         #[ValidateNotNullOrEmpty()]
         [string[]]$ComputerName = $env:COMPUTERNAME
     )
     foreach ($comp in $ComputerName)
     {
         $output = @{ 'ComputerName' = $comp }
         $output.UserName = (Get-CimInstance -ClassName win32_computersystem -ComputerName $comp).UserName
         [PSCustomObject]$output
     }
 }

Function Find-VMByIPExact {
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
	VMware.VimAutomation.Core\get-vm | where {$_.guest.IPAddress -like $IP} | select name,@{N="DnsName"; E={$_.ExtensionData.Guest.Hostname}},@{n="Notes";e={$psitem | select -ExpandProperty notes}},@{n="OS";e={$psitem.guest.OSFullName}},@{N="IPAddresses";E={@($_.guest.IPAddress)}},@{n="Tags";e={($psitem | Get-TagAssignment).tag}},powerstate,VMHost,CreateDate,persistentid,@{n="ClusterRule";e={(get-drsclustergroup -vm $psitem).name}},@{n="vCenter";e={(((($psitem.uid).split("@"))[1]).split("."))[0]}}

	nutanix.Prism.PS.Cmds\get-vm | Where-Object { $psitem.ipaddresses -like "*$IP*" } | Select vmname,dnsname,description,numVCpus,memoryCapacityInBytes,ipaddresses,powerstate,hostName,vmId,nutanixVirtualDisks,diskCapacityInBytes

}

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

Function Get-VMInfoAllVMs_CSV {
		    <#
    .SYNOPSIS
        Lists VM info for all VMs
		
	.PARAMETER Name
		VM Name to output info
		
    .OUTPUTS
        VM Name, DNS name, VM notes, OS, and IP Addresses

    #>
	
	$FilePrefix = get-date -Format yyyy.MM.dd.ss
	$ReportVM = "$FilePrefix.AllVMwareVMInfo.csv"
	$ReportNutanix = "$FilePrefix.AllNutanixVMInfo.csv"
	
	VMware.VimAutomation.Core\get-vm |   select name,
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
	HardwareVersion	| export-csv -path c:\temp\$reportVM
		
	nutanix.Prism.PS.Cmds\get-vm | Select vmname,dnsname,description,numVCpus,memoryCapacityInBytes,ipaddresses,powerstate,hostName,vmId,nutanixVirtualDisks,diskCapacityInBytes | export-csv -path c:\temp\$ReportNutanix
	
	Write-host "Save output to c:\temp\"$report
}
	
function Test-Credential {
    <#
    .SYNOPSIS
        Takes a PSCredential object and validates it against the domain (or local machine, or ADAM instance).

    .PARAMETER credential
        A PSCredential object with the username/password you wish to test. Typically this is generated using the Get-Credential cmdlet. Accepts pipeline input.

    .PARAMETER context
        An optional parameter specifying what type of credential this is. Possible values are 'Domain','Machine',and 'ApplicationDirectory.' The default is 'Domain.'

    .OUTPUTS
        A boolean, indicating whether the credentials were successfully validated.

    #>
    param(
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [System.Management.Automation.PSCredential]$credential,
        [parameter()][validateset('Domain','Machine','ApplicationDirectory')]
        [string]$context = 'Domain'
    )
    begin {
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
    }
    process {
        # Extract domain and username from the credential
        $userNameParts = $credential.UserName -split '\\'
        if ($userNameParts.Length -eq 2) {
            $domain = $userNameParts[0]
            $userName = $userNameParts[1]
        } else {
            $domain = $null
            $userName = $credential.UserName
        }

        # Create PrincipalContext with domain if specified
        if ($domain) {
            $principalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::$context, $domain)
        } else {
            $principalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::$context)
        }

        # Validate credentials
        $isValid = $principalContext.ValidateCredentials($userName, $credential.GetNetworkCredential().Password)
        Write-Output $isValid
    }
}

Function Find-InstalledApplicationOnAllWorkstations {
[cmdletbinding()]
	param(  
		[Parameter(mandatory)][string]$Application = "Sectra"
			) #End param

$FilePrefix = get-date -Format yyyy.MM.dd.ss
$Report = "$FilePrefix.$Application.csv"

$Query = "select Version from Win32_Product where Name like '%$Application%'"
$13DaysAgo = (get-date).adddays(-13)
$ActiveWorkstations = Get-ADComputer -Filter {(modified -gt $13DaysAgo) -and (operatingsystem -notlike "*server*") -and (enabled -eq $TRUE) -and  (name -notlike "ctx*")}
$Found = Get-CimInstance -ComputerName $ActiveWorkstations.Name -Query $Query -OperationTimeoutSec 60 -ErrorAction SilentlyContinue
$Found | sort Name | select Name,Version,PSComputerName
$Found | measure | select count
$Found | export-csv -Path $Report
Write-host "Output save to "$Report
}

Function Find-InstalledApplicationOnAllServers {
[cmdletbinding()]
	param(  
		[Parameter(mandatory)][string]$Application = "Sectra"
			) #End param

$FilePrefix = get-date -Format yyyy.MM.dd.ss
$Report = "$FilePrefix.$Application.csv"

$Query = "select Version from Win32_Product where Name like '%$Application%'"
$13DaysAgo = (get-date).adddays(-13)
$ActiveWorkstations = Get-ADComputer -Filter {(modified -gt $13DaysAgo) -and (operatingsystem -like "*server*") -and (enabled -eq $TRUE)}
$Found = Get-CimInstance -ComputerName $ActiveWorkstations.Name -Query $Query -OperationTimeoutSec 60 -ErrorAction SilentlyContinue
$Found | sort Name | select Name,Version,PSComputerName
$Found | measure | select count
$Found | export-csv -Path $Report
Write-host "Output save to "$Report
}

Function Find-InstalledApplication {
[cmdletbinding()]
	param(  
		[Parameter(mandatory)][string]$ComputerName = $env:computername, 
        [Parameter(mandatory)][string]$Application = "Sectra"
			) #End param

$Query = "select Version from Win32_Product where Name like '%$Application%'"
Get-CimInstance -ComputerName $ComputerName -Query $Query -OperationTimeoutSec 60 | select Name,Version
}

Function Find-ADUser {
<#
.SYNOPSIS
Finds enabled AD users matching a partial name, username, or display name.

.DESCRIPTION
Searches Active Directory for user objects using ANR (Ambiguous Name Resolution), excluding disabled accounts (UAC 1.2). Returns full [ADUser] objects with all properties loaded.

.PARAMETER SearchString
Enter part of the name, username, or display name to search for. This is a mandatory parameter and supports pipeline input.

.EXAMPLE
Find-ADUser "tim"
Returns all enabled AD users matching "tim" in name, username, or display name.

.EXAMPLE
"tim" | Find-ADUser
Demonstrates pipeline input.

.NOTES
Author: Greg Pennings
Supports -WhatIf and -Confirm via CmdletBinding.

.LINK
Get-ADUser
#>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([Microsoft.ActiveDirectory.Management.ADUser])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$SearchString
    )

    process {
        if ($PSCmdlet.ShouldProcess($SearchString, "Search AD for matching users")) {
            Get-ADUser -LDAPFilter "(&(objectCategory=person)(objectClass=user)(!(userAccountControl:1.2.840.113556.1.4.803:=2))(anr=$SearchString))" -Properties *
        }
    }
}

Function Remove-VmAudioDevice_OGV {
Write-host "This will take a while. Be patient."
$VMs = VMware.VimAutomation.Core\get-vm | sort $pstem.name
foreach ($vm in $VMs) {if ($vm.ExtensionData.Config.Hardware.Device | where {$_.GetType().Name -eq "VirtualHdAudioCard"}) {[array]$VmWithAudio += $vm.name}}
$vmName = $VmWithAudio | ogv -PassThru
	
Try{

   $vm = VMware.VimAutomation.Core\get-vm -Name $vmName -ErrorAction Stop

   switch($vm.PowerState){

   'poweredon' {

  Shutdown-VMGuest -VM $vm -Confirm:$false

   while($vm.PowerState -eq 'PoweredOn'){

  sleep 5

   $vm = VMware.VimAutomation.Core\get-vm -Name $vmName

   }

   }

   Default {

   Write-Host "VM '$($vmName)' is not powered on!"

   }

   }

   Write-Host "$($vmName) has shutdown. It should be ready for configuration."

}

Catch{

   Write-Host "VM '$($vmName)' not found!"

} # end poweroff VM
	
	$audio = $vm.ExtensionData.Config.Hardware.Device | where {$_.GetType().Name -eq "VirtualHdAudioCard"} 
	
	$spec = New-Object VMware.Vim.VirtualMachineConfigSpec
	$dev = New-Object VMware.Vim.VirtualDeviceConfigSpec
	$dev.Device = $audio
	$dev.Operation = "remove"
	$spec.deviceChange += $dev
	
$vm.ExtensionData.ReconfigVM($spec)

Start-VM $vmName
}

Function Get-ADUserGroupMembership {
	[cmdletbinding()]
	param(  
		[Parameter(mandatory)][string]$UserName = $env:username 
			) #End param
	(Get-ADUser -Identity $UserName -Properties MemberOf |Select-Object MemberOf).MemberOf | get-adgroup | sort name | select name
}

Function Get-ADUserGroupMembership_OGV {
 (get-aduser -Filter {enabled -eq "True"} -Properties samaccountname,memberof | select name,userprincipalname,samaccountname,memberof | sort userprincipalname | ogv -PassThru).memberof | get-adgroup | select name | sort name
}

Function Get-ADGroupMember_OGV {
Get-ADGroupMember -Identity (Get-ADGroup -Filter * |select name,samaccountname |ogv -PassThru).samaccountname | sort name | select name,samaccountname
}

Function Get-CertificateCryptographicProvider_OGV {
$signature = @"
[DllImport("Crypt32.dll", SetLastError = true, CharSet = CharSet.Auto)]
public static extern bool CertGetCertificateContextProperty(
    IntPtr pCertContext,
    uint dwPropId,
    IntPtr pvData,
    ref uint pcbData
);
[StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
public struct CRYPT_KEY_PROV_INFO {
    [MarshalAs(UnmanagedType.LPWStr)]
    public string pwszContainerName;
    [MarshalAs(UnmanagedType.LPWStr)]
    public string pwszProvName;
    public uint dwProvType;
    public uint dwFlags;
    public uint cProvParam;
    public IntPtr rgProvParam;
    public uint dwKeySpec;
}
[DllImport("ncrypt.dll", SetLastError = true)]
public static extern int NCryptOpenStorageProvider(
    ref IntPtr phProvider,
    [MarshalAs(UnmanagedType.LPWStr)]
    string pszProviderName,
    uint dwFlags
);
[DllImport("ncrypt.dll", SetLastError = true)]
public static extern int NCryptOpenKey(
    IntPtr hProvider,
    ref IntPtr phKey,
    [MarshalAs(UnmanagedType.LPWStr)]
    string pszKeyName,
    uint dwLegacyKeySpec,
    uint dwFlags
);
[DllImport("ncrypt.dll", SetLastError = true)]
public static extern int NCryptGetProperty(
    IntPtr hObject,
    [MarshalAs(UnmanagedType.LPWStr)]
    string pszProperty,
    byte[] pbOutput,
    int cbOutput,
    ref int pcbResult,
    int dwFlags
);
[DllImport("ncrypt.dll", CharSet=CharSet.Auto, SetLastError=true)]
public static extern int NCryptFreeObject(
    IntPtr hObject
);
"@
Add-Type -MemberDefinition $signature -Namespace PKI -Name Tools

#
#

$CERT_KEY_PROV_INFO_PROP_ID = 0x2 # from Wincrypt.h header file
# $cert = (get-childitem -LiteralPath Cert:\LocalMachine\My\ | where {$psitem.issuer -like "*Let's*"})
$cert = get-childitem -LiteralPath Cert:\LocalMachine\My\ | ogv -PassThru
# initialize variables
$pcbData = 0
# get buffer size that will contain provider information
[void][PKI.Tools]::CertGetCertificateContextProperty($cert.Handle,$CERT_KEY_PROV_INFO_PROP_ID,[IntPtr]::Zero,[ref]$pcbData)
# allocate this buffer in unmanaged memory
$pvData = [Runtime.InteropServices.Marshal]::AllocHGlobal($pcbData)
# call the function again to copy provider information to a pointer.
[PKI.Tools]::CertGetCertificateContextProperty($cert.Handle,$CERT_KEY_PROV_INFO_PROP_ID,$pvData,[ref]$pcbData)
# copy structure from unmanaged memory to a managed structure
$keyProv = [Runtime.InteropServices.Marshal]::PtrToStructure($pvData,[type][PKI.Tools+CRYPT_KEY_PROV_INFO])
# we don't need unmanaged buffer, so release it
[Runtime.InteropServices.Marshal]::FreeHGlobal($pvData)
# display the key provider information
$keyProv
}

function Get-VIEventPlus {
<#  
.SYNOPSIS  Returns vSphere events    
.DESCRIPTION The function will return vSphere events. With
    the available parameters, the execution time can be
   improved, compered to the original Get-VIEvent cmdlet.
.NOTES  Author:  Luc Dekens  
.PARAMETER Entity
   When specified the function returns events for the
   specific vSphere entity. By default events for all
   vSphere entities are returned.
.PARAMETER EventType
   This parameter limits the returned events to those
   specified on this parameter.
.PARAMETER Start
   The start date of the events to retrieve
.PARAMETER Finish
   The end date of the events to retrieve.
.PARAMETER Recurse
   A switch indicating if the events for the children of
   the Entity will also be returned
.PARAMETER User
   The list of usernames for which events will be returned
.PARAMETER System
   A switch that allows the selection of all system events.
.PARAMETER ScheduledTask
   The name of a scheduled task for which the events
   will be returned
.PARAMETER FullMessage
   A switch indicating if the full message shall be compiled.
   This switch can improve the execution speed if the full
   message is not needed.  
.EXAMPLE
   PS> Get-VIEventPlus -Entity $vm
.EXAMPLE
   PS> Get-VIEventPlus -Entity $cluster -Recurse:$true
#>
 
  param(
    [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl[]]$Entity,
    [string[]]$EventType,
    [DateTime]$Start,
    [DateTime]$Finish = (Get-Date),
    [switch]$Recurse,
    [string[]]$User,
    [Switch]$System,
    [string]$ScheduledTask,
    [switch]$FullMessage = $false
  )
 
  process {
    $eventnumber = 100
    $events = @()
    $eventMgr = Get-View EventManager
    $eventFilter = New-Object VMware.Vim.EventFilterSpec
    $eventFilter.disableFullMessage = ! $FullMessage
    $eventFilter.entity = New-Object VMware.Vim.EventFilterSpecByEntity
    $eventFilter.entity.recursion = &{if($Recurse){"all"}else{"self"}}
    $eventFilter.eventTypeId = $EventType
    if($Start -or $Finish){
      $eventFilter.time = New-Object VMware.Vim.EventFilterSpecByTime
    if($Start){
        $eventFilter.time.beginTime = $Start
    }
    if($Finish){
        $eventFilter.time.endTime = $Finish
    }
    }
  if($User -or $System){
    $eventFilter.UserName = New-Object VMware.Vim.EventFilterSpecByUsername
    if($User){
      $eventFilter.UserName.userList = $User
    }
    if($System){
      $eventFilter.UserName.systemUser = $System
    }
  }
  if($ScheduledTask){
    $si = Get-View ServiceInstance
    $schTskMgr = Get-View $si.Content.ScheduledTaskManager
    $eventFilter.ScheduledTask = Get-View $schTskMgr.ScheduledTask |
      where {$_.Info.Name -match $ScheduledTask} |
      Select -First 1 |
      Select -ExpandProperty MoRef
  }
  if(!$Entity){
    $Entity = @(Get-Folder -Name Datacenters)
  }
  $entity | %{
      $eventFilter.entity.entity = $_.ExtensionData.MoRef
      $eventCollector = Get-View ($eventMgr.CreateCollectorForEvents($eventFilter))
      $eventsBuffer = $eventCollector.ReadNextEvents($eventnumber)
      while($eventsBuffer){
        $events += $eventsBuffer
        $eventsBuffer = $eventCollector.ReadNextEvents($eventnumber)
      }
      $eventCollector.DestroyCollector()
    }
    $events
  }
}
 
function Get-MotionHistory {
<#  
.SYNOPSIS  Returns the vMotion/svMotion history    
.DESCRIPTION The function will return information on all
   the vMotions and svMotions that occurred over a specific
    interval for a defined number of virtual machines
.NOTES  Author:  Luc Dekens  
.PARAMETER Entity
   The vSphere entity. This can be one more virtual machines,
   or it can be a vSphere container. If the parameter is a
    container, the function will return the history for all the
   virtual machines in that container.
.PARAMETER Days
   An integer that indicates over how many days in the past
   the function should report on.
.PARAMETER Hours
   An integer that indicates over how many hours in the past
   the function should report on.
.PARAMETER Minutes
   An integer that indicates over how many minutes in the past
   the function should report on.
.PARAMETER Sort
   An switch that indicates if the results should be returned
   in chronological order.
.EXAMPLE
   PS> Get-MotionHistory -Entity $vm -Days 1
.EXAMPLE
   PS> Get-MotionHistory -Entity $cluster -Sort:$false
.EXAMPLE
   PS> Get-Datacenter -Name $dcName |
   >> Get-MotionHistory -Days 7 -Sort:$false
#>
 
  param(
    [CmdletBinding(DefaultParameterSetName="Days")]
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl[]]$Entity,
    [Parameter(ParameterSetName='Days')]
    [int]$Days = 1,
    [Parameter(ParameterSetName='Hours')]
    [int]$Hours,
    [Parameter(ParameterSetName='Minutes')]
    [int]$Minutes,
    [switch]$Recurse = $false,
    [switch]$Sort = $true
  )
 
  begin{
    $history = @()
    switch($psCmdlet.ParameterSetName){
      'Days' {
        $start = (Get-Date).AddDays(- $Days)
      }
      'Hours' {
        $start = (Get-Date).AddHours(- $Hours)
      }
      'Minutes' {
        $start = (Get-Date).AddMinutes(- $Minutes)
      }
    }
    $eventTypes = "DrsVmMigratedEvent","VmMigratedEvent"
  }
 
  process{
    $history += Get-VIEventPlus -Entity $entity -Start $start -EventType $eventTypes -Recurse:$Recurse |
    Select CreatedTime,
    @{N="Type";E={
        if($_.SourceDatastore.Name -eq $_.Ds.Name){"vMotion"}else{"svMotion"}}},
    @{N="UserName";E={if($_.UserName){$_.UserName}else{"System"}}},
    @{N="VM";E={$_.VM.Name}},
    @{N="SrcVMHost";E={$_.SourceHost.Name.Split('.')[0]}},
    @{N="TgtVMHost";E={if($_.Host.Name -ne $_.SourceHost.Name){$_.Host.Name.Split('.')[0]}}},
    @{N="SrcDatastore";E={$_.SourceDatastore.Name}},
    @{N="TgtDatastore";E={if($_.Ds.Name -ne $_.SourceDatastore.Name){$_.Ds.Name}}}
  }
 
  end{
    if($Sort){
      $history | Sort-Object -Property CreatedTime
    }
    else{
      $history
    }
  }
}

Function Test-URI {
<#
.Synopsis
Test a URI or URL
.Description
This command will test the validity of a given URL or URI that begins with either http or https. The default behavior is to write a Boolean value to the pipeline. But you can also ask for more detail.
 
Be aware that a URI may return a value of True because the server responded correctly. For example this will appear that the URI is valid.
 
test-uri -uri http://files.snapfiles.com/localdl936/CrystalDiskInfo7_2_0.zip
 
But if you look at the test in detail:
 
ResponseUri   : http://files.snapfiles.com/localdl936/CrystalDiskInfo7_2_0.zip
ContentLength : 23070
ContentType   : text/html
LastModified  : 1/19/2015 11:34:44 AM
Status        : 200
 
You'll see that the content type is Text and most likely a 404 page. By comparison, this is the desired result from the correct URI:
 
PS C:\> test-uri -detail -uri http://files.snapfiles.com/localdl936/CrystalDiskInfo6_3_0.zip
 
ResponseUri   : http://files.snapfiles.com/localdl936/CrystalDiskInfo6_3_0.zip
ContentLength : 2863977
ContentType   : application/x-zip-compressed
LastModified  : 12/31/2014 1:48:34 PM
Status        : 200
 
.Example
PS C:\> test-uri https://petri.com
True
.Example
PS C:\> test-uri https://petri.com -detail
 
ResponseUri   : https://petri.com/
ContentLength : -1
ContentType   : text/html; charset=UTF-8
LastModified  : 1/19/2015 12:14:57 PM
Status        : 200
.Example
PS C:\> get-content D:\temp\uris.txt | test-uri -Detail | where { $_.status -ne 200 -OR $_.contentType -notmatch "application"}
 
ResponseUri   : http://files.snapfiles.com/localdl936/CrystalDiskInfo7_2_0.zip
ContentLength : 23070
ContentType   : text/html
LastModified  : 1/19/2015 11:34:44 AM
Status        : 200
 
ResponseURI   : http://download.bleepingcomputer.com/grinler/rkill
ContentLength : 
ContentType   : 
LastModified  : 
Status        : 404
 
Test a list of URIs and filter for those that are not OK or where the type is not an application.
.Notes
Last Updated: January 19, 2015
Version     : 1.0
 
Learn more about PowerShell:
http://jdhitsolutions.com/blog/essential-powershell-resources/
 
  ****************************************************************
  * DO NOT USE IN A PRODUCTION ENVIRONMENT UNTIL YOU HAVE TESTED *
  * THOROUGHLY IN A LAB ENVIRONMENT. USE AT YOUR OWN RISK.  IF   *
  * YOU DO NOT UNDERSTAND WHAT THIS SCRIPT DOES OR HOW IT WORKS, *
  * DO NOT USE IT OUTSIDE OF A SECURE, TEST SETTING.             *
  ****************************************************************
 
.Link
Invoke-WebRequest
#>
 
[cmdletbinding(DefaultParameterSetName="Default")]
Param(
[Parameter(Position=0,Mandatory,HelpMessage="Enter the URI path starting with HTTP or HTTPS",
ValueFromPipeline,ValueFromPipelineByPropertyName)]
[ValidatePattern( "^(http|https)://" )]
[Alias("url")]
[string]$URI,
[Parameter(ParameterSetName="Detail")]
[Switch]$Detail,
[ValidateScript({$_ -ge 0})]
[int]$Timeout = 30
)
 
Begin {
    Write-Verbose -Message "Starting $($MyInvocation.Mycommand)" 
    Write-Verbose -message "Using parameter set $($PSCmdlet.ParameterSetName)" 
} #close begin block
 
Process {
 
    Write-Verbose -Message "Testing $uri"
    Try {
     #hash table of parameter values for Invoke-Webrequest
     $paramHash = @{
     UseBasicParsing = $True
     DisableKeepAlive = $True
     Uri = $uri
     Method = 'Head'
     ErrorAction = 'stop'
     TimeoutSec = $Timeout
    }
 
    $test = Invoke-WebRequest @paramHash
 
     if ($Detail) {
        $test.BaseResponse | 
        Select ResponseURI,ContentLength,ContentType,LastModified,
        @{Name="Status";Expression={$Test.StatusCode}}
     } #if $detail
     else {
       if ($test.statuscode -ne 200) {
            #it is unlikely this code will ever run but just in case
            Write-Verbose -Message "Failed to request $uri"
            write-Verbose -message ($test | out-string)
            $False
         }
         else {
            $True
         }
     } #else quiet
     
    }
    Catch {
      #there was an exception getting the URI
      write-verbose -message $_.exception
      if ($Detail) {
        #most likely the resource is 404
        $objProp = [ordered]@{
        ResponseURI = $uri
        ContentLength = $null
        ContentType = $null
        LastModified = $null
        Status = 404
        }
        #write a matching custom object to the pipeline
        New-Object -TypeName psobject -Property $objProp
 
        } #if $detail
      else {
        $False
      }
    } #close Catch block
} #close Process block
 
End {
    Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"
} #close end block
 
} #close Test-URI Function

function Get-Uptime {
	[cmdletbinding()]
	param(  
		[Parameter(mandatory)][string]$ComputerName = $env:computername 
		 ) #End param
	Get-CimInstance -ComputerName $ComputerName Win32_OperatingSystem | Select-Object  CSName, Caption, ServicePackMajorVersion, OSArchitecture, LastBootUpTime
}

function Remove-Snapshot_OGV {
	$VM = (VMware.VimAutomation.Core\get-vm | get-snapshot | sort created | select VM,Name,Created,id | ogv -PassThru)
	VMware.VimAutomation.Core\get-vm $VM.vm.name | get-snapshot | where {$PSItem.Id -eq $VM.id} | Remove-Snapshot -RunAsync -confirm:$false
}

function Get-ProfilesFromRemoteComputer {
	[cmdletbinding()]
	param(  
		[Parameter(mandatory)][string]$ComputerName = $env:computername 
		 ) #End param
	Get-CimInstance -CimSession $ComputerName -query "select * from win32_userprofile where Loaded=$false and Special=$false"
}

function Remove-ProfilesFromRemoteComputer {
	[cmdletbinding()]
	param(  
		[Parameter(mandatory)][string]$ComputerName = $env:computername 
		 ) #End param
	Get-CimInstance -CimSession $ComputerName -query "select * from win32_userprofile where Loaded=$false and Special=$false" | Remove-CimInstance
}

function Get-MyCredential{
	param(
	$CredPath,
	[switch]$Help
	)
	$HelpText = @"

    Get-MyCredential
    Usage:
    Get-MyCredential -CredPath `$CredPath

    If a credential is stored in $CredPath, it will be used.
    If no credential is found, Export-Credential will start and offer to
    Store a credential at the location specified.

"@
    if($Help -or (!($CredPath))){write-host $Helptext; Break}
    if (!(Test-Path -Path $CredPath -PathType Leaf)) {
        Export-Credential (Get-Credential) $CredPath
    }
    $cred = Import-Clixml $CredPath
    $cred.Password = $cred.Password | ConvertTo-SecureString
    $Credential = New-Object System.Management.Automation.PsCredential($cred.UserName, $cred.Password)
    Return $Credential
} #end Get-MyCredential

function Export-Credential($cred, $path) {
	# Export-Credential
	# Usage: Export-Credential $CredentialObject $FileToSaveTo
      $cred = $cred | Select-Object *
      $cred.password = $cred.Password | ConvertFrom-SecureString
      $cred | Export-Clixml $path
}

function Get-IndependentDrives {
	VMware.VimAutomation.Core\get-vm | where {($PSItem | Get-HardDisk | where {$PSItem.Persistence -like "IndependentP*"}) -and ($psitem.powerstate -eq "PoweredOn")} |
	Select-Object Name,@{n='HD Name';e={($PSItem | Get-HardDisk | where {$PSItem.Persistence -like "IndependentP*"}).Name}},@{n="vCenter";e={(((($psitem.uid).split("@"))[1]).split("."))[0]}} |
	Sort-Object vCenter,Name
} # end Get-IndependentDrives - Independent Persistent drives of Powered On VMs

function Get-CitrixSessionsAll {
	Get-BrokerSession |select HostedMachineName,AppState,SessionState,BrokeringUserName | sort HostedMachineName | ft -AutoSize -Force
}

function Clean-CitrixDisconnectedSessions {
	Add-PSSnapin Citrix.*.Admin.V*
	$CitrixController = "hcixenadc01.hci.pvt"
	$vCenterServer = "hcidalvc01"

	#Count Disconnected Sessions
	$sessions = (Get-BrokerSession -Filter { SessionState -eq 'Disconnected' } -AdminAddress hcixenadc01.hci.pvt -Property SessionKey | Measure-Object).count

	# Clear Disconnected Sessions
	if ($sessions) {
					try {
						Get-BrokerSession -Filter { SessionState -eq 'Disconnected' } -AdminAddress hcixenadc01.hci.pvt | Stop-BrokerSession | Out-Null
						$wait = $sessions + 10 # Wait no less than 10 seconds for sessions to close
						Write-Host "Waiting $wait seconds"
						Start-Sleep -Seconds $wait
						} #end try
					catch {
						$error[0] | ft -AutoSize
						Write-Host "The error is probably because the first VDI in this list"
						Get-BrokerSession -Filter { SessionState -eq 'Disconnected' } -AdminAddress hcixenadc01.hci.pvt -Property DNSName | ft
						Break
						} #end catch
					} # End clear Disonnected Sessions if

	# Clear App not running
	Get-BrokerSession -Filter { AppState -eq 'NoApps' -and SessionType -eq 'Application'} -AdminAddress hcixenadc01.hci.pvt | Stop-BrokerSession

	# Wait for disconnected sessions to finish clearing
	$sessions = (Get-BrokerSession -Filter { SessionState -eq 'Disconnected' } -AdminAddress hcixenadc01.hci.pvt -Property SessionKey | Measure-Object).count
	$wait = $sessions * 10 # set Wait 10 seconds for every session
	Write-Host "Waiting $wait seconds for $sessions to close"
	start-sleep -Seconds $wait

	# Prompt for hung session computers to restart
	$RestartComputers = (Get-BrokerSession -Filter { SessionState -eq 'Disconnected' } -AdminAddress hcixenadc01.hci.pvt |
		select HostedMachineName,StartTime,SessionStateChangeTime, IPAddress, AppState|
			ogv -Title "Force Reboot of Selected Citrix Workstations" -PassThru)

	#Logoff Users
	#    foreach ($computername in $RestartComputers.HostedMachineName) {
	#        $logOffUser = ((quser /Server:$computername | ConvertFrom-String) | ogv -PassThru)
	#        $column3 = $logOffUser.P3
	#        $column4 = $logOffUser.P4
	#        
	#        foreach ($user in $column3) {
	#            logOff $user /Server:$ComputerName
	#            } #end foreach user loop
	#        foreach ($usertoo in $colmun4) {
	#            logoff $usertoo /Server:$ComputerName
	#            } #end foreach usertoo
	#    } #end foreach logoff users

	#Restart if hung computers selected
	if ($RestartComputers.ipaddress) {
		write-host "Powering off selected computers. Citrix will power them back on automatically."
		write-host "You will need to confirm in a moment. Please stand by."
		Connect-VIServer -server hcidalvc01
		foreach ($computer in $RestartComputers)
			{
			$targetVM = VMware.VimAutomation.Core\get-vm |VMware.VimAutomation.Core\get-vmGuest |where IPAddress -like "$computer*"
			stop-vm -VM $targetVM.VmName -Confirm
			} #end foreach
		 
		} # End Restart if
	get-date
} #end Clean-CitrixDisconnectedSessions

function Clean-CitrixSessions1Hr {
	Add-PSSnapin Citrix.*.Admin.V*
	$CitrixController = "hcixenadc01.hci.pvt"
	$vCenterServer = "hcidalvc01"
	$now = get-date
	$hourold = $now.AddHours(-1)
	$OldSessions = (Get-BrokerSession -Filter {SessionStateChangeTime -lt $hourold -and SessionState -eq 'Disconnected'} -AdminAddress hcixenadc01.hci.pvt)

	# Clear Disconnected Sessions


	try {
		$oldSessions | Stop-BrokerSession 
		#Start-Sleep 15
		#$OldSessions = (Get-BrokerSession -Filter {SessionStateChangeTime -lt $hourold -and SessionState -eq 'Disconnected'} -AdminAddress hcixenadc01.hci.pvt)
		#$oldSessions | sort SessionStateChangeTime | Select SessionState,AppState,DNSName,SessionStateChangeTime,LogoffInProgress | Format-Table
		} #end try
	catch {
		$error[0] | ft -AutoSize
		Write-Host "The error is probably because the first VDI in this list"
		Get-BrokerSession -Filter { SessionState -eq 'Disconnected' } -AdminAddress hcixenadc01.hci.pvt -Property DNSName | ft
		Break
		} #end catch

	# Clear App not running
	Get-BrokerSession -Filter { SessionStateChangeTime -lt $hourold -and AppState -eq 'NoApps' -and SessionType -eq 'Application' -and SessionState -eq 'Active'} -AdminAddress hcixenadc01.hci.pvt | Stop-BrokerSession

	Write-host $now
}#End Clean-CitrixSessions1Hr

function Clear-CitrixLocalPassword {
	# This will delete the Citrix saved passwords one at a time

	[cmdletbinding()]
	param(  
		[Parameter(mandatory)][string]$ComputerName = $env:computername 
			) #End param


	if (Test-Connection -ComputerName $ComputerName -Count 1 -ErrorAction SilentlyContinue) {
	if (-NOT (Test-WSMan -ComputerName $ComputerName -ErrorAction SilentlyContinue)) {c:\tools\PowerTools\PSExec \\$ComputerName Powershell Enable-PSRemoting -Force -SkipNetworkProfileCheck}

	c:\tools\PowerTools\PSExec \\$ComputerName "C:\Program Files (x86)\Citrix\ICA Client\SelfServicePlugin\SelfService.exe" -deletePasswords
	#Invoke-Command -computerName $ComputerName -FilePath 'C:\Program Files (x86)\Citrix\ICA Client\SelfServicePlugin\SelfService.exe' -ArgumentList "-deletePasswords"
			
	} #end if Test-Connection
	else {Write-Host "Not on network"} #end else Test-Connection
} #End Clear-CitrixLocalPassword

function Get-RDUserLogoff_OGV {
	#Get user on remote computer
	[cmdletbinding()]
	param( [Parameter(mandatory)][string]$ComputerName = $env:computername ) #End param
	
	Invoke-Command -ComputerName $ComputerName -ScriptBlock {Get-Process -IncludeUserName | Select-Object UserName,SessionId | Where-Object {$PSItem.UserName -ne $null -and $PSItem.UserName.StartsWith("TSRH") -and $PSItem.SessionId -ne "0"}} | sort sessionID -Unique | ogv
}

function Invoke-RDUserLogoff_OGV {
	#Log off users remotely
	[cmdletbinding()]
	param( [Parameter(mandatory)][string]$ComputerName = $env:computername ) #End param
	
	$SessionToLogOff = Invoke-Command -ComputerName $ComputerName -ScriptBlock {Get-Process -IncludeUserName | Select-Object UserName,SessionId | Where-Object {$PSItem.UserName -ne $null -and $PSItem.UserName.StartsWith("TSRH") -and $PSItem.SessionId -ne "0"}} | sort sessionID -Unique | ogv -PassThru

	if ($SessionToLogOff) {
        Invoke-RDUserLogoff -HostServer $ComputerName -UnifiedSessionID $SessionToLogOff.SessionId -ErrorAction SilentlyContinue -Force
		} #end if
	else {
		Write-host "No users logged on $ComputerName" -ForegroundColor Green
		} #end else
}

function Clear-LoggedOnSessions_OGV {
	#Log off users remotely

	[cmdletbinding()]
	param( [Parameter(mandatory)][string]$ComputerName = $env:computername ) #End param
	if (-not(Test-Connection $ComputerName -Count 1 -Quiet)) {
	   Write-Host "$ComputerName did not ping. May need to adjust firewall."
	}#End ping fail

	$logOffUser = ((quser /Server:$ComputerName | ConvertFrom-String) | ogv -PassThru)
	$column3 = $logOffUser.P3
	$column4 = $logOffUser.P4

	foreach ($user in $column3) {
		logOff $user /Server:$ComputerName
		} #end foreach user loop

	foreach ($usertoo in $colmun4) {
		logoff $usertoo /Server:$ComputerName
		} #end foreach usertoo loop

} #End Clear-LoggedOnSessions_OGV

function Clear-LoggedOnSessions {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RemoteComputerName
    )

    # Get the list of logged-in users
    $users = quser /server:$RemoteComputerName | Select-Object -Skip 1 | ForEach-Object {
        $parts = $_ -split '\s{2,}'
        [PSCustomObject]@{
            UserName    = $parts[0]
            SessionName = $parts[1]
            SessionID   = $parts[2]
            State       = $parts[3]
            IdleTime    = $parts[4]
            LogonTime   = $parts[5]
        }
    }

    # Display the users in a grid view and allow multiple selections
    $selectedUsers = $users | Out-GridView -Title "Select users to log off" -PassThru

    # Log off the selected users
    foreach ($user in $selectedUsers) {
        if ($user.SessionID -match 'rdp-tcp#\d+') {
            # Handle RDP session IDs
            $sessionName = $user.SessionID
            Invoke-Command -ComputerName $RemoteComputerName -ScriptBlock { logoff $using:sessionName }
        } else {
            # Handle numeric session IDs
            Invoke-RDUserLogoff -HostServer $RemoteComputerName -UnifiedSessionID $user.SessionID -Force
        }
    }
} #End Clear-LoggedOnSessions

function Enable-RemoteDesktop {
	[cmdletbinding()]
	param(  
		[Parameter(mandatory)][string]$ComputerName = $env:computername 
		 ) #End param

	if (-not(Test-Connection $ComputerName -Count 1 -Quiet)) {
	   Write-Host "$ComputerName did not ping. May need to adjust firewall."
	}#End ping fail

		if (-not((Test-NetConnection $ComputerName -CommonTCPPort WINRM).TcpTestSucceeded)) {c:\tools\PowerTools\psexec -s \\$computername winrm.cmd quickconfig -q} #Enable WinRM	

	$RDP =  Test-NetConnection $ComputerName -CommonTCPPort RDP
				if ($RDP.TcpTestSucceeded) {
					Write-Host "RDP Already enabled"
					} #End if Already enabled
				else {
					$Session = New-PSSession -ComputerName $ComputerName
						invoke-command -Session $Session -scriptblock {
							Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -Value 0
							Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
							} #End Scriptblock

						Test-NetConnection $ComputerName -CommonTCPPort RDP
					 } #end else RDP not enabled script block
} #End Enable-RemoteDesktop

function Enable-WinRM {
	[cmdletbinding()]
	param(  
		[Parameter(mandatory)][string]$ComputerName = $env:computername 
			) #End param

	if (-NOT (Test-Connection $ComputerName -Count 1 -ErrorAction SilentlyContinue)) {
		Write-Host "$ComputerName not responding to ping"
		} #End if
	if (-NOT (Test-WSMan -ComputerName $ComputerName -ErrorAction SilentlyContinue)) {
		c:\tools\PowerTools\psexec -s \\$computername winrm.cmd quickconfig -q
		} #end config WSMan if
	else {
		Write-Host "Already enabled"
		} #end config WSMan else
} #End Enable-WinRM

function Enable-WinRMSSL {
	[cmdletbinding()]
	param(  
		[Parameter(mandatory)][string]$ComputerName = $env:computername 
			) #End param

	if (Test-Connection $ComputerName -Count 1 -ErrorAction SilentlyContinue) {
		c:\tools\PowerTools\psexec -s \\$computername winrm.cmd quickconfig -transport:https -q
		} #end Test-Connection if and WinRm config
	else {
		Write-Host "$ComputerName not responding to ping"
		} #end Test-Connection else
} #End Enable-WinRMSSL

function Get-AllServersInComputersContainer {
	#find Servers in Computer container and put them into an array
	$ServerList = Get-ADComputer -Filter {operatingsystem -like "*server*"} -SearchBase "CN=Computers,DC=HCI,DC=PVT" -Server hcidaldc01 -Properties CN,Created,OperatingSystem,DistinguishedName | select CN,Created,OperatingSystem,DistinguishedName
	Write-Host "These Servers are in the Computer OU"
	$ServerList
} #End Get-AllServersInComputersContainer

function Get-CitrixGhostSessions {
	#Get-CitrixUsersThatNeedToBeHidden

	Add-PSSnapin Citrix.*.Admin.V*
	$CitrixController = "hcixenadc01.hci.pvt"
	$now = get-date
	$2hourold = $now.AddHours(-2)
	$OldSessions = (Get-BrokerSession -Filter {SessionStateChangeTime -lt $2hourold -and AppState -eq 'NoApps'} -AdminAddress $CitrixController)

	# Get Disconnected Sessions


	try {
		$oldSessions | sort SessionStateChangeTime | Select DNSName,SessionStateChangeTime,LogoffInProgress,UserFullName,username,hidden | Format-Table
		} #end try
	catch {
		$error[0] | ft -AutoSize
		Write-Host "The error is probably because the first VDI in this list"
		Get-BrokerSession -Filter { SessionState -eq 'Disconnected' } -AdminAddress $CitrixController -Property DNSName | ft
		Break
		} #end catch
} #End Get-CitrixGhostSessions

function Get-CitrixLoggingOffSessions {
	Add-PSSnapin Citrix.*.Admin.V*
	$CitrixController = "hcixenadc01.hci.pvt"
	$vCenterServer = "hcidalvc01"

	# Get App not running
	Get-BrokerSession -Filter {LogoffInProgress -eq 'True'} -AdminAddress hcixenadc01.hci.pvt | Select DNSName,LogoffInProgress,UserFullName,username,hidden | sort DNSName | format-table

	Write-host $now
} #End Get-CitrixLoggingOffSessions

function Get-CitrixOldDisconnectedSessions {
	Add-PSSnapin Citrix.*.Admin.V*
	$CitrixController = "hcixenadc01.hci.pvt"
	$vCenterServer = "hcidalvc01"
	$now = get-date
	$hourold = $now.AddHours(-1)
	$OldSessions = (Get-BrokerSession -Filter {SessionStateChangeTime -and SessionState -eq 'Disconnected'} -AdminAddress $CitrixController)

	# Get Old Disconnected Sessions


	try {
		$oldSessions | sort SessionStateChangeTime | Select SessionState,AppState,DNSName,SessionStateChangeTime,LogoffInProgress,UserFullName,hidden | Format-Table
		} #end try
	catch {
		$error[0] | ft -AutoSize
		Write-Host "The error is probably because the first VDI in this list"
		Get-BrokerSession -Filter { SessionState -eq 'Disconnected' } -AdminAddress $CitrixController -Property DNSName | ft
		Break
		} #end catch

	# Get App not running
	Get-BrokerSession -Filter { SessionStateChangeTime -and AppState -eq 'NoApps' -and SessionType -eq 'Application' -and SessionState -eq 'Active'} -AdminAddress hcixenadc01.hci.pvt | sort SessionStateChangeTime | Select SessionState,AppState,DNSName,SessionStateChangeTime,LogoffInProgress,UserFullName,hidden | Format-Table

	Write-host $now
} #End Get-CitrixSessions

function Get-CitrixSessons1Hr {
	Add-PSSnapin Citrix.*.Admin.V*
	$CitrixController = "hcixenadc01.hci.pvt"
	$vCenterServer = "hcidalvc01"
	$now = get-date
	$hourold = $now.AddHours(-1)
	$OldSessions = (Get-BrokerSession -Filter {SessionStateChangeTime -lt $hourold -and SessionState -eq 'Disconnected'} -AdminAddress $CitrixController)

	# Get Disconnected Sessions


	try {
		$oldSessions | sort SessionStateChangeTime | Select SessionState,AppState,DNSName,SessionStateChangeTime,LogoffInProgress,UserFullName,hidden | Format-Table
		} #end try
	catch {
		$error[0] | ft -AutoSize
		Write-Host "The error is probably because the first VDI in this list"
		Get-BrokerSession -Filter { SessionState -eq 'Disconnected' } -AdminAddress $CitrixController -Property DNSName | ft
		Break
		} #end catch

	# Get App not running
	Get-BrokerSession -Filter { SessionStateChangeTime -lt $hourold -and AppState -eq 'NoApps' -and SessionType -eq 'Application' -and SessionState -eq 'Active'} -AdminAddress hcixenadc01.hci.pvt | sort SessionStateChangeTime | Select SessionState,AppState,DNSName,SessionStateChangeTime,LogoffInProgress,UserFullName,username | Format-Table

	Write-host $now
} #End Get-CitrixSessons1Hr

function Get-LoggedOnSessions_OGV {
	#Get logged on users of remote workstations

	[cmdletbinding()]
	param(  
		[Parameter(mandatory)][string]$ComputerName = $env:computername 
			) #End param

	if (Test-Connection $ComputerName -Count 1 -ErrorAction SilentlyContinue) {
		(quser /Server:$ComputerName | ConvertFrom-String) | ogv
		} #End if
} #End Get-LoggedOnSessions

Function Get-SystemInfo {
	<#
	.SYNOPSIS
	Get Complete details of any server Local or remote
	.DESCRIPTION
	This function uses WMI class to connect to remote machine and get all related details
	.PARAMETER COMPUTERNAMES
	Just Pass computer name as Its parameter
	.EXAMPLE 
	Get-SystemInfo
	.EXAMPLE 
	Get-SystemInfo -ComputerName HQSPDBSP01
	.NOTES
	To get help:
	Get-Help Get-SystemInfo
	.LINK
	http://sqlpowershell.wordpress.com
	#>

	param(
		[Parameter(Mandatory=$true)] $ComputerName,
		[switch] $IgnorePing
		 )


	$computer = $ComputerName

	# Declare main data hash to be populated later
	$data = @{}

	$data.' ComputerName'=$computer

	# Try an ICMP ping the only way Powershell knows how...
	$ping = Test-Connection -quiet -count 1 $computer
	$Ping = $(if ($ping) { 'Yes' } else { 'No' })

	# Do a DNS lookup with a .NET class method. Suppress error messages.
	$ErrorActionPreference = 'SilentlyContinue'
	if ( $ips = [System.Net.Dns]::GetHostAddresses($computer) | foreach { $_.IPAddressToString } ) {
		
		$data.'IP Address(es) from DNS' = ($ips -join ', ')
		
	}

	else {
		
		$data.'IP Address from DNS' = 'Could not resolve'
		
	}
	# Make errors visible again
	$ErrorActionPreference = 'Continue'

	# We'll assume no ping reply means it's dead. Try this anyway if -IgnorePing is specified
	if ($ping -or $ignorePing) {
		
		$data.'WMI Data Collection Attempt' = 'Yes (ping reply or -IgnorePing)'
		
		# Get various info from the ComputerSystem WMI class
		if ($wmi = Get-WmiObject -Computer $computer -Class Win32_ComputerSystem -ErrorAction SilentlyContinue) {
			
			$data.'Computer Hardware Manufacturer' = $wmi.Manufacturer
			$data.'Computer Hardware Model'        = $wmi.Model
			$data.'Memory Physical in MB'          = ($wmi.TotalPhysicalMemory/1MB).ToString('N')
			$data.'Logged On User'                 = $wmi.Username
			
		}
		
		$wmi = $null
		
		# Get the free/total disk space from local disks (DriveType 3)
		if ($wmi = Get-WmiObject -Computer $computer -Class Win32_LogicalDisk -Filter 'DriveType=3' -ErrorAction SilentlyContinue) {
			
			$wmi | Select 'DeviceID', 'Size', 'FreeSpace' | Foreach {
				
				$data."Local disk $($_.DeviceID)" = ('' + ($_.FreeSpace/1MB).ToString('N') + ' MB free of ' + ($_.Size/1MB).ToString('N') + ' MB total space with ' + ($_.Size/1MB - $_.FreeSpace/1MB).ToString('N') +' MB Used Space')
				
				
			}
			
		}
		
		$wmi = $null
		
		# Get IP addresses from all local network adapters through WMI
		if ($wmi = Get-WmiObject -Computer $computer -Class Win32_NetworkAdapterConfiguration -ErrorAction SilentlyContinue) {
			
			$Ips = @{}
			
			$wmi | Where { $_.IPAddress -match '\S+' } | Foreach { $Ips.$($_.IPAddress -join ', ') = $_.MACAddress }
			
			$counter = 0
			$Ips.GetEnumerator() | Foreach {
				
				$counter++; $data."IP Address $counter" = '' + $_.Name + ' (MAC: ' + $_.Value + ')'
				
			}
			
		}
		
		$wmi = $null
		
		# Get CPU information with WMI
		if ($wmi = Get-WmiObject -Computer $computer -Class Win32_Processor -ErrorAction SilentlyContinue) {
			
			$wmi | Foreach {
				
				$maxClockSpeed     =  $_.MaxClockSpeed
				$numberOfCores     += $_.NumberOfCores
				$description       =  $_.Description
				$numberOfLogProc   += $_.NumberOfLogicalProcessors
				$socketDesignation =  $_.SocketDesignation
				$status            =  $_.Status
				$manufacturer      =  $_.Manufacturer
				$name              =  $_.Name
				
			}
			
			$data.'CPU Clock Speed'        = $maxClockSpeed
			$data.'CPU Cores'              = $numberOfCores
			$data.'CPU Description'        = $description
			$data.'CPU Logical Processors' = $numberOfLogProc
			$data.'CPU Socket'             = $socketDesignation
			$data.'CPU Status'             = $status
			$data.'CPU Manufacturer'       = $manufacturer
			$data.'CPU Name'               = $name -replace '\s+', ' '
			
		}
		
		$wmi = $null
		
		# Get BIOS info from WMI
		if ($wmi = Get-WmiObject -Computer $computer -Class Win32_Bios -ErrorAction SilentlyContinue) {
			
			$data.'BIOS Manufacturer' = $wmi.Manufacturer
			$data.'BIOS Name'         = $wmi.Name
			$data.'BIOS Version'      = $wmi.Version
			
		}
		
		$wmi = $null
		
		# Get operating system info from WMI
		if ($wmi = Get-WmiObject -Computer $computer -Class Win32_OperatingSystem -ErrorAction SilentlyContinue) {
			
			$data.'OS Boot Time'     = $wmi.ConvertToDateTime($wmi.LastBootUpTime)
			$data.'OS System Drive'  = $wmi.SystemDrive
			$data.'OS System Device' = $wmi.SystemDevice
			$data.'OS Language     ' = $wmi.OSLanguage
			$data.'OS Version'       = $wmi.Version
			$data.'OS Windows dir'   = $wmi.WindowsDirectory
			$data.'OS Name'          = $wmi.Caption
			$data.'OS Install Date'  = $wmi.ConvertToDateTime($wmi.InstallDate)
			$data.'OS Service Pack'  = [string]$wmi.ServicePackMajorVersion + '.' + $wmi.ServicePackMinorVersion
			
		}
		
		# Scan for open ports
		$ports = @{ 
					'File shares/RPC' = '139' ;
					'File shares'     = '445' ;
					'RDP'             = '3389';
					#'Zenworks'        = '1761';
				  }
		
		foreach ($service in $ports.Keys) {
			
			$socket = New-Object Net.Sockets.TcpClient
			
			# Suppress error messages
			$ErrorActionPreference = 'SilentlyContinue'
			
			# Try to connect
			$socket.Connect($computer, $ports.$service)
			
			# Make error messages visible again
			$ErrorActionPreference = 'Continue'
			
			if ($socket.Connected) {
				
				$data."Port $($ports.$service) ($service)" = 'Open'
				$socket.Close()
				
			}
			
			else {
				
				$data."Port $($ports.$service) ($service)" = 'Closed or filtered'
				
			}
			
			$socket = $null
			
		}
		
	}

	else {
		
		$data.'WMI Data Collected' = 'No (no ping reply and -IgnorePing not specified)'
		
	}

	$wmi = $null


	if ($wmi = Get-WmiObject -Class Win32_OperatingSystem -computername $Computer -ErrorAction SilentlyContinue| Select-Object Name, TotalVisibleMemorySize, FreePhysicalMemory,TotalVirtualMemorySize,FreeVirtualMemory,FreeSpaceInPagingFiles,NumberofProcesses,NumberOfUsers ) {
			
			$wmi | Foreach {
				
				$TotalRAM     =  $_.TotalVisibleMemorySize/1MB
				$FreeRAM     = $_.FreePhysicalMemory/1MB
				$UsedRAM       =  $_.TotalVisibleMemorySize/1MB - $_.FreePhysicalMemory/1MB
				$TotalRAM = [Math]::Round($TotalRAM, 2)
				$FreeRAM = [Math]::Round($FreeRAM, 2)
				$UsedRAM = [Math]::Round($UsedRAM, 2)
				$RAMPercentFree = ($FreeRAM / $TotalRAM) * 100
				$RAMPercentFree = [Math]::Round($RAMPercentFree, 2)
				$TotalVirtualMemorySize  = [Math]::Round($_.TotalVirtualMemorySize/1MB, 3)
				$FreeVirtualMemory =  [Math]::Round($_.FreeVirtualMemory/1MB, 3)
				$FreeSpaceInPagingFiles            =  [Math]::Round($_.FreeSpaceInPagingFiles/1MB, 3)
				$NumberofProcesses      =  $_.NumberofProcesses
				$NumberOfUsers              =  $_.NumberOfUsers
				
			}
			$data.'Memory - Total RAM GB '  = $TotalRAM
			$data.'Memory - RAM Free GB'    = $FreeRAM
			$data.'Memory - RAM Used GB'    = $UsedRAM
			$data.'Memory - Percentage Free'= $RAMPercentFree
			$data.'Memory - TotalVirtualMemorySize' = $TotalVirtualMemorySize
			$data.'Memory - FreeVirtualMemory' = $FreeVirtualMemory
			$data.'Memory - FreeSpaceInPagingFiles' = $FreeSpaceInPagingFiles
			$data.'NumberofProcesses'= $NumberofProcesses
			$data.'NumberOfUsers'    = $NumberOfUsers -replace '\s+', ' '
			
		}

	# Output data
	"#"*80
	"OS Complete Information"
	"Generated $(get-date)"
	"Generated from $(gc env:computername)"
	"#"*80

	$data.GetEnumerator() | Sort-Object 'Name' | Format-Table -AutoSize
	$data.GetEnumerator() | Sort-Object 'Name' | Out-GridView -Title "$computer Information"
} #End Get-SystemInfo

Function Get-CitrixUnregisteredMachines {
	Add-PSSnapin Citrix.*.Admin.V*
	Get-BrokerMachine  -AdminAddress hcixenadc01.hci.pvt -Filter {(RegistrationState -eq "Unregistered") -and (InMaintenanceMode -eq "False")} |
	select hostedmachinename,powerstate,inmaintenancemode
} #End Get-CitrixUnregisteredVDISessions

Function Clear-AutoRunCD {
	# This script will disable autorun CD for individual machines
	# by prompting for a machine name

	$remotecomp = Read-Host -Prompt 'Which workstation?'
	$s = New-PSSession -computerName $remotecomp
	Invoke-Command -Session $s -Scriptblock {
		New-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer -name "NoDriveTypeAutoRun" -Value "177" -PropertyType "dword"
		} #End Invoke Scriptblock

	Remove-PSSession $s
} #End Clear-AutoRunCD

Function Clean-DesktopIcons {
	# This was created to remove desktop icons

	# This script will remove desktop icons for individual machines
	# by prompting for a machine name

	$remotecomp = Read-Host -Prompt 'Which Server'
	#c:\tools\PowerTools\PSExec \\$remotecomp Powershell Enable-PSRemoting -Force -SkipNetworkProfileCheck
	$cred = Get-Credential tsrh\priv-isglp
	$s = New-PSSession -computerName $remotecomp -credential $cred
	Invoke-Command -Session $s -Scriptblock {

	New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS

	$Account=(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\' AutoLogonSID).AutoLogonSID

	New-ItemProperty -Path HKU:\$Account\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel -name "{645FF040-5081-101B-9F08-00AA002F954E}" -Value "00000001" -PropertyType "dword"

	Set-ItemProperty -Path HKU:\$Account\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel -name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value "00000001"
	Set-ItemProperty -Path HKU:\$Account\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel -name "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" -Value "00000001"
	Set-ItemProperty -Path HKU:\$Account\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel -name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value "00000001"

	New-Item -Path HKU:\$Account\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons -Name ClassicStartMenu
	New-ItemProperty -Path HKU:\$Account\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu -name "{645FF040-5081-101B-9F08-00AA002F954E}" -Value "00000001" -PropertyType "dword"
	New-ItemProperty -Path HKU:\$Account\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu -name "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" -Value "00000001" -PropertyType "dword"
	New-ItemProperty -Path HKU:\$Account\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu -name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value "00000001" -PropertyType "dword"
	New-ItemProperty -Path HKU:\$Account\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu -name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value "00000001" -PropertyType "dword"

	Remove-PSDrive -Name HKU
	}

	Remove-PSSession $s
} #End Clean-DesktopIcons

Function Restart-CitrixUnregistered_OGV {
# Prompt for hung session computers to restart
Add-PSSnapin Citrix.*.Admin.V*
$CitrixController = "hcixenadc01.hci.pvt"
$vCenterServer = "hcidalvc01"

$RestartComputers = (Get-BrokerMachine -Property HostedMachineName,FaultState,LastDeregistrationReason,LastDeregistrationTime,SummaryState -AdminAddress hcixenadc01.hci.pvt |
where faultstate -eq "Unregistered" |
select HostedMachineName,LastDeregistrationReason,LastDeregistrationTime,SummaryState |
ogv -PassThru).HostedMachineName

#Restart if hung computers selected
if ($RestartComputers) {
    write-host "Powering off selected computers. Citrix will power them back on automatically."
    write-host "You will need to confirm in a moment. Please stand by."
    Connect-VIServer -server hcidalvc01
    foreach ($computer in $RestartComputers)
        {VMware.VimAutomation.Core\get-vm -name $computer | stop-vm -Confirm} #end foreach
         } # End Restart if
	get-date
} #End Restart-CitriUnregistered

Function Get-CitrixUnregistered_OGV {
# List hung Citrix session computers
Add-PSSnapin Citrix.*.Admin.V*
$CitrixController = "hcixenadc01.hci.pvt"

Get-BrokerMachine -Property HostedMachineName,FaultState,LastDeregistrationReason,LastDeregistrationTime,SummaryState -AdminAddress hcixenadc01.hci.pvt |
where faultstate -eq "Unregistered" |
select HostedMachineName,LastDeregistrationReason,LastDeregistrationTime,SummaryState |
ogv

} #End Get-CitrixUnregistered

Function Restart-ComputerAndPing {
	#Script to restart computers and ping them

	[cmdletbinding()]
	param(  
		[Parameter(mandatory)][string]$ComputerName = $env:computername 
			) #End param

	Restart-Computer -ComputerName $ComputerName
	start cmd -Args "/c ping $ComputerName -t"
}

Function Set-CitrixHungSesstionToGhost_OGV {
#Set-CitrixUsersThatNeedToBeHidden

Add-PSSnapin Citrix.*.Admin.V*
$CitrixController = "hcixenadc01.hci.pvt"
$now = get-date
$2hourold = $now.AddHours(-2)
$GhostSessions = (Get-BrokerSession -Filter {AppState -eq 'NoApps' -and Hidden -eq 'False'} -AdminAddress $CitrixController) | sort SessionStateChangeTime | Select SessionState,AppState,DNSName,SessionStateChangeTime,LogoffInProgress,UserFullName,Username,Hidden | ogv -PassThru

# Get Disconnected Sessions

try {foreach ($hider in $GhostSessions)
        {
        get-brokersession -UserFullName $hider.userfullname | Set-BrokerSession -hidden $true
        } #end foreach
    } #end try
catch {
    $error[0] | ft -AutoSize
    Write-Host "The error is probably because the first VDI in this list"
    Get-BrokerSession -Filter { SessionState -eq 'Disconnected' } -AdminAddress $CitrixController -Property DNSName | ft
    Break
    } #end catch
}

Function Stop-ComputerAndPing {
#Script to restart computers and ping them

[cmdletbinding()]
param(  
    [Parameter(mandatory)][string]$ComputerName = $env:computername 
        ) #End param

Stop-Computer -ComputerName $ComputerName
start cmd -Args "/c ping $ComputerName -t"
}

function Start-RDP {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Cred
    )

    # Extract username and password
    $username = $Cred.UserName
    $password = $Cred.GetNetworkCredential().Password

    # Store credentials using cmdkey
    cmdkey /add:$ComputerName /user:$username /pass:$password

    # Create a temporary RDP file
    $rdpPath = [System.IO.Path]::GetTempFileName() + ".rdp"
    @"
screen mode id:i:1
desktopwidth:i:1920
desktopheight:i:1080
session bpp:i:32
full address:s:$ComputerName
username:s:$username
authentication level:i:2
prompt for credentials:i:0
"@ | Set-Content -Path $rdpPath -Encoding ASCII

    # Find the first available Code Signing certificate
    $cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object {
        $_.EnhancedKeyUsageList.FriendlyName -contains "Code Signing"
    } | Select-Object -First 1

    if (-not $cert) {
        Write-Warning "No code signing certificate found. Proceeding without signing."
    } else {
        # Sign the RDP file
        $thumbprint = $cert.Thumbprint -replace '\s',''
        & rdpsign.exe /sha256 $thumbprint $rdpPath
    }

    # Start RDP session
    Start-Process "mstsc.exe" -ArgumentList "`"$rdpPath`""

    # Run cleanup in the background
    Start-Job -ScriptBlock {
        param($target, $file)
        Start-Sleep -Seconds 30
        cmdkey /delete:$target
        Remove-Item -Path $file -Force
    } -ArgumentList $ComputerName, $rdpPath | Out-Null
}

Add-Type -AssemblyName System.Windows.Forms #not sure where needed but Module didn't load without this

function New-IsoFile {  
  <# .Synopsis Creates a new .iso file .Description The New-IsoFile cmdlet creates a new .iso file containing content from chosen folders .Example New-IsoFile "c:\tools","c:Downloads\utils" This command creates a .iso file in $env:temp folder (default location) that contains c:\tools and c:\downloads\utils folders. The folders themselves are included at the root of the .iso image. .Example New-IsoFile -FromClipboard -Verbose Before running this command, select and copy (Ctrl-C) files/folders in Explorer first. .Example dir c:\WinPE | New-IsoFile -Path c:\temp\WinPE.iso -BootFile "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\efisys.bin" -Media DVDPLUSR -Title "WinPE" This command creates a bootable .iso file containing the content from c:\WinPE folder, but the folder itself isn't included. Boot file etfsboot.com can be found in Windows ADK. Refer to IMAPI_MEDIA_PHYSICAL_TYPE enumeration for possible media types: http://msdn.microsoft.com/en-us/library/windows/desktop/aa366217(v=vs.85).aspx .Notes NAME: New-IsoFile AUTHOR: Chris Wu LASTEDIT: 03/23/2016 14:46:50 #> 
   
  [CmdletBinding(DefaultParameterSetName='Source')]Param( 
    [parameter(Position=1,Mandatory=$true,ValueFromPipeline=$true, ParameterSetName='Source')]$Source,  
    [parameter(Position=2)][string]$Path = "$env:temp\$((Get-Date).ToString('yyyyMMdd-HHmmss.ffff')).iso",  
    [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})][string]$BootFile = $null, 
    [ValidateSet('CDR','CDRW','DVDRAM','DVDPLUSR','DVDPLUSRW','DVDPLUSR_DUALLAYER','DVDDASHR','DVDDASHRW','DVDDASHR_DUALLAYER','DISK','DVDPLUSRW_DUALLAYER','BDR','BDRE')][string] $Media = 'DVDPLUSRW_DUALLAYER', 
    [string]$Title = (Get-Date).ToString("yyyyMMdd-HHmmss.ffff"),  
    [switch]$Force, 
    [parameter(ParameterSetName='Clipboard')][switch]$FromClipboard 
  ) 
  
  Begin {  
    ($cp = new-object System.CodeDom.Compiler.CompilerParameters).CompilerOptions = '/unsafe' 
    if (!('ISOFile' -as [type])) {  
      Add-Type -CompilerParameters $cp -TypeDefinition @'
public class ISOFile  
{ 
  public unsafe static void Create(string Path, object Stream, int BlockSize, int TotalBlocks)  
  {  
    int bytes = 0;  
    byte[] buf = new byte[BlockSize];  
    var ptr = (System.IntPtr)(&bytes);  
    var o = System.IO.File.OpenWrite(Path);  
    var i = Stream as System.Runtime.InteropServices.ComTypes.IStream;  
   
    if (o != null) { 
      while (TotalBlocks-- > 0) {  
        i.Read(buf, BlockSize, ptr); o.Write(buf, 0, bytes);  
      }  
      o.Flush(); o.Close();  
    } 
  } 
}  
'@  
    } 
   
    if ($BootFile) { 
      if('BDR','BDRE' -contains $Media) { Write-Warning "Bootable image doesn't seem to work with media type $Media" } 
      ($Stream = New-Object -ComObject ADODB.Stream -Property @{Type=1}).Open()  # adFileTypeBinary 
      $Stream.LoadFromFile((Get-Item -LiteralPath $BootFile).Fullname) 
      ($Boot = New-Object -ComObject IMAPI2FS.BootOptions).AssignBootImage($Stream) 
    } 
  
    $MediaType = @('UNKNOWN','CDROM','CDR','CDRW','DVDROM','DVDRAM','DVDPLUSR','DVDPLUSRW','DVDPLUSR_DUALLAYER','DVDDASHR','DVDDASHRW','DVDDASHR_DUALLAYER','DISK','DVDPLUSRW_DUALLAYER','HDDVDROM','HDDVDR','HDDVDRAM','BDROM','BDR','BDRE') 
  
    Write-Verbose -Message "Selected media type is $Media with value $($MediaType.IndexOf($Media))"
    ($Image = New-Object -com IMAPI2FS.MsftFileSystemImage -Property @{VolumeName=$Title}).ChooseImageDefaultsForMediaType($MediaType.IndexOf($Media)) 
   
    if (!($Target = New-Item -Path $Path -ItemType File -Force:$Force -ErrorAction SilentlyContinue)) { Write-Error -Message "Cannot create file $Path. Use -Force parameter to overwrite if the target file already exists."; break } 
  }  
  
  Process { 
    if($FromClipboard) { 
      if($PSVersionTable.PSVersion.Major -lt 5) { Write-Error -Message 'The -FromClipboard parameter is only supported on PowerShell v5 or higher'; break } 
      $Source = Get-Clipboard -Format FileDropList 
    } 
  
    foreach($item in $Source) { 
      if($item -isnot [System.IO.FileInfo] -and $item -isnot [System.IO.DirectoryInfo]) { 
        $item = Get-Item -LiteralPath $item
      } 
  
      if($item) { 
        Write-Verbose -Message "Adding item to the target image: $($item.FullName)"
        try { $Image.Root.AddTree($item.FullName, $true) } catch { Write-Error -Message ($_.Exception.Message.Trim() + ' Try a different media type.') } 
      } 
    } 
  } 
  
  End {  
    if ($Boot) { $Image.BootImageOptions=$Boot }  
    $Result = $Image.CreateResultImage()  
    [ISOFile]::Create($Target.FullName,$Result.ImageStream,$Result.BlockSize,$Result.TotalBlocks) 
    Write-Verbose -Message "Target image ($($Target.FullName)) has been created"
    $Target
  } 
} 
