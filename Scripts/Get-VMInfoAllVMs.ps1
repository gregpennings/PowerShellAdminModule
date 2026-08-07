<#
.SYNOPSIS
Returns inventory information for all VMs across VMware, Nutanix, and/or Hyper-V.

.DESCRIPTION
Queries all VMs and returns their inventory details as objects. By default all
platforms -- VMware (vSphere), Nutanix (Prism), and Hyper-V -- are queried, and the
objects are emitted to the pipeline so you can sort, filter, format, or export them.

Hyper-V is queried over the CIM sessions mounted by Connect-HyperVHost; clustered
VMs are deduped by VM id. If no Hyper-V hosts are connected, the Hyper-V pass is
skipped with a warning.

Progress is reported per platform as "Phase N of <total>: <platform>", with the
percent complete reflecting how far through that platform's VM list the script is
(not the overall run).

Use -ExportCsv to write the results to CSV instead -- one file per platform, each
named with the run's timestamp, all inside a single timestamped folder (via
New-FolderNameWithTimestamp). In that mode the script returns the file path(s)
rather than the VM objects.

.PARAMETER Platform
Which platform(s) to query: VMware, Nutanix, HyperV, or All (default).

.PARAMETER ExportCsv
Write results to CSV file(s) and return the path(s) instead of the VM objects. One
timestamped file per platform queried, all inside one timestamped folder.

.PARAMETER Path
Parent directory for the timestamped export folder when -ExportCsv is used.
Defaults to the configured DefaultExportPath (see Get-AdminConfig).

.EXAMPLE
.\Get-VMInfoAllVMs.ps1
Returns all VMware, Nutanix, and Hyper-V VM objects to the pipeline.

.EXAMPLE
.\Get-VMInfoAllVMs.ps1 -Platform VMware | Where-Object PowerState -eq 'PoweredOn'
Returns only VMware VMs, filtered to those powered on.

.EXAMPLE
.\Get-VMInfoAllVMs.ps1 -ExportCsv
Writes <timestamp>.VMware.csv / <timestamp>.Nutanix.csv / <timestamp>.HyperV.csv
into one timestamped folder under C:\temp (or the configured DefaultExportPath)
and returns the file paths.

.NOTES
Moved out of the module (Public\Get-VMInfoAllVMs.ps1) into Scripts\ -- this is a
one-off inventory sweep, not a building-block cmdlet other functions call.
#>
[CmdletBinding()]
param(
    [ValidateSet('VMware', 'Nutanix', 'HyperV', 'All')]
    [string]$Platform = 'All',

    [switch]$ExportCsv,

    [string]$Path
)

Import-Module Admin -ErrorAction Stop

if (-not $Path) { $Path = (Get-AdminConfig).DefaultExportPath }

$phases = @()
if ($Platform -in 'VMware', 'All')  { $phases += 'VMware' }
if ($Platform -in 'Nutanix', 'All') { $phases += 'Nutanix' }
if ($Platform -in 'HyperV', 'All')  { $phases += 'HyperV' }

$exportFolder = $null
$runTimestamp = $null
if ($ExportCsv) {
    $exportFolder = New-FolderNameWithTimestamp -Subject 'VMInfoAllVMs' -Path $Path -IncludeSeconds
    $runTimestamp = Get-Date -Format 'yyyyMMddHHmmss'
}

$exported = @()
$phaseNumber = 0

foreach ($platformName in $phases) {
    $phaseNumber++
    $progress = @{
        Id       = 1
        Activity = 'Get-VMInfoAllVMs'
        Status   = "Phase $phaseNumber of $($phases.Count): $platformName"
    }
    Write-Progress @progress -PercentComplete 0 -CurrentOperation 'Retrieving VM list...'

    switch ($platformName) {

        'VMware' {
            $vms = @(VMware.VimAutomation.Core\Get-VM)
            $results = for ($i = 0; $i -lt $vms.Count; $i++) {
                $vm = $vms[$i]
                Write-Progress @progress -PercentComplete ([int](100 * ($i + 1) / $vms.Count)) `
                    -CurrentOperation "VM $($i + 1) of $($vms.Count): $($vm.Name)"

                [PSCustomObject]@{
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
                    vCenter            = ($vm.Uid.Split('@')[1]).Split('.')[0]
                    'Oldest Snapshot'  = (Get-Snapshot -VM $vm | Sort-Object Created | Select-Object -First 1).Created
                    Datastore          = (Get-Datastore -Id $vm.DatastoreIdList).Name
                    Folder             = $vm.Folder.Name
                    UsedSpaceGB        = [math]::Round($vm.UsedSpaceGB, 2)
                    ProvisionedSpaceGB = [math]::Round(($vm | Get-HardDisk | Measure-Object -Property CapacityGB -Sum).Sum, 2)
                    HardwareVersion    = $vm.HardwareVersion
                }
            }
        }

        'Nutanix' {
            $vms = @(nutanix.Prism.PS.Cmds\Get-VM)
            $results = for ($i = 0; $i -lt $vms.Count; $i++) {
                $vm = $vms[$i]
                Write-Progress @progress -PercentComplete ([int](100 * ($i + 1) / $vms.Count)) `
                    -CurrentOperation "VM $($i + 1) of $($vms.Count): $($vm.vmname)"

                $vm | Select-Object vmname, dnsname, description, numVCpus, memoryCapacityInBytes,
                    ipaddresses, powerstate, hostName, vmId, nutanixVirtualDisks, diskCapacityInBytes
            }
        }

        'HyperV' {
            $sessions = @(Get-HyperVSession)
            if ($sessions.Count -eq 0) {
                Write-Warning "No Hyper-V hosts connected; skipping Hyper-V. Run Connect-HyperVHost first."
                $results = @()
            } else {
                # Fetch first (fast) so the total VM count is known up front, then
                # enrich with network adapters (slow) in a second, progress-tracked pass.
                $seen = [System.Collections.Generic.HashSet[string]]::new()
                $allVms = @()
                foreach ($session in $sessions) {
                    try {
                        $sessionVms = Hyper-V\Get-VM -CimSession $session -ErrorAction Stop
                    } catch {
                        Write-Warning "Failed to query Hyper-V host '$($session.ComputerName)': $_"
                        continue
                    }
                    foreach ($vm in $sessionVms) {
                        if ($seen.Add([string]$vm.VMId)) { $allVms += $vm }
                    }
                }

                $results = for ($i = 0; $i -lt $allVms.Count; $i++) {
                    $vm = $allVms[$i]
                    Write-Progress @progress -PercentComplete ([int](100 * ($i + 1) / [math]::Max($allVms.Count, 1))) `
                        -CurrentOperation "VM $($i + 1) of $($allVms.Count): $($vm.Name)"

                    $ips = @()
                    try {
                        $ips = @($vm | Hyper-V\Get-VMNetworkAdapter -ErrorAction Stop |
                            ForEach-Object { $_.IPAddresses } | Where-Object { $_ })
                    } catch { $ips = @() }

                    [PSCustomObject]@{
                        Name                 = $vm.Name
                        State                = $vm.State
                        ProcessorCount       = $vm.ProcessorCount
                        MemoryStartupGB      = [math]::Round($vm.MemoryStartup / 1GB, 2)
                        IPAddresses          = $ips -join ', '
                        VMHost               = $vm.ComputerName
                        IsClustered          = $vm.IsClustered
                        CreationTime         = $vm.CreationTime
                        VMId                 = $vm.VMId
                        ConfigurationVersion = $vm.Version
                        Notes                = $vm.Notes
                    }
                }
            }
        }
    }

    Write-Progress @progress -PercentComplete 100 -CurrentOperation 'Done'

    if ($ExportCsv) {
        $file = Join-Path $exportFolder.FullName "$runTimestamp.$platformName.csv"
        $results | Export-Csv -Path $file -NoTypeInformation
        $exported += $file
    } else {
        $results
    }
}

Write-Progress -Id 1 -Activity 'Get-VMInfoAllVMs' -Completed

if ($ExportCsv) {
    Write-Verbose "Exported $($exported.Count) file(s) to $($exportFolder.FullName)"
    $exported
}
