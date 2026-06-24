function Get-SystemInfo {
    <#
    .SYNOPSIS
        Gets a broad set of hardware, OS, network, memory, and open-port details for
        a computer (local or remote).

    .DESCRIPTION
        Queries the target via CIM (Win32_ComputerSystem, Win32_LogicalDisk,
        Win32_NetworkAdapterConfiguration, Win32_Processor, Win32_Bios,
        Win32_OperatingSystem), does a DNS lookup, scans a few common TCP ports, and
        presents a consolidated report as a sorted table and an Out-GridView.

    .PARAMETER ComputerName
        The computer to inspect.

    .PARAMETER IgnorePing
        Attempt data collection even if the computer does not reply to ping.

    .EXAMPLE
        Get-SystemInfo -ComputerName HQSPDBSP01

    .EXAMPLE
        Get-SystemInfo -ComputerName SERVER01 -IgnorePing

    .OUTPUTS
        None (writes a formatted table and an Out-GridView).

    .NOTES
        Uses CIM (WS-Management) for remote queries; the target must have WinRM
        enabled. Original concept: sqlpowershell.wordpress.com.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [switch]$IgnorePing
    )

    $computer = $ComputerName
    $data = @{}
    $data.' ComputerName' = $computer

    # ICMP ping
    $ping = Test-Connection -Quiet -Count 1 -ComputerName $computer

    # DNS lookup via .NET
    try {
        $ips = [System.Net.Dns]::GetHostAddresses($computer) | ForEach-Object { $_.IPAddressToString }
        $data.'IP Address(es) from DNS' = ($ips -join ', ')
    } catch {
        $data.'IP Address from DNS' = 'Could not resolve'
    }

    if ($ping -or $IgnorePing) {
        $data.'CIM Data Collection Attempt' = 'Yes (ping reply or -IgnorePing)'

        # ComputerSystem
        if ($cs = Get-CimInstance -ComputerName $computer -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue) {
            $data.'Computer Hardware Manufacturer' = $cs.Manufacturer
            $data.'Computer Hardware Model'        = $cs.Model
            $data.'Memory Physical in MB'          = ($cs.TotalPhysicalMemory / 1MB).ToString('N')
            $data.'Logged On User'                 = $cs.UserName
        }

        # Local fixed disks (DriveType 3)
        Get-CimInstance -ComputerName $computer -ClassName Win32_LogicalDisk -Filter 'DriveType=3' -ErrorAction SilentlyContinue |
            Select-Object DeviceID, Size, FreeSpace |
            ForEach-Object {
                $data."Local disk $($_.DeviceID)" =
                    '' + ($_.FreeSpace / 1MB).ToString('N') + ' MB free of ' +
                    ($_.Size / 1MB).ToString('N') + ' MB total space with ' +
                    ($_.Size / 1MB - $_.FreeSpace / 1MB).ToString('N') + ' MB Used Space'
            }

        # Network adapter IP/MAC
        if ($adapters = Get-CimInstance -ComputerName $computer -ClassName Win32_NetworkAdapterConfiguration -ErrorAction SilentlyContinue) {
            $addressMap = @{}
            $adapters | Where-Object { $_.IPAddress -match '\S+' } | ForEach-Object {
                $addressMap.$($_.IPAddress -join ', ') = $_.MACAddress
            }
            $counter = 0
            $addressMap.GetEnumerator() | ForEach-Object {
                $counter++
                $data."IP Address $counter" = '' + $_.Name + ' (MAC: ' + $_.Value + ')'
            }
        }

        # CPU
        if ($processors = Get-CimInstance -ComputerName $computer -ClassName Win32_Processor -ErrorAction SilentlyContinue) {
            $numberOfCores   = 0
            $numberOfLogProc = 0
            foreach ($p in $processors) {
                $maxClockSpeed     = $p.MaxClockSpeed
                $numberOfCores    += $p.NumberOfCores
                $description       = $p.Description
                $numberOfLogProc  += $p.NumberOfLogicalProcessors
                $socketDesignation = $p.SocketDesignation
                $status            = $p.Status
                $manufacturer      = $p.Manufacturer
                $name              = $p.Name
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

        # BIOS
        if ($bios = Get-CimInstance -ComputerName $computer -ClassName Win32_Bios -ErrorAction SilentlyContinue) {
            $data.'BIOS Manufacturer' = $bios.Manufacturer
            $data.'BIOS Name'         = $bios.Name
            $data.'BIOS Version'      = $bios.Version
        }

        # Operating system (CIM returns real DateTime values -- no ConvertToDateTime needed)
        if ($os = Get-CimInstance -ComputerName $computer -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue) {
            $data.'OS Boot Time'     = $os.LastBootUpTime
            $data.'OS System Drive'  = $os.SystemDrive
            $data.'OS System Device' = $os.SystemDevice
            $data.'OS Language'      = $os.OSLanguage
            $data.'OS Version'       = $os.Version
            $data.'OS Windows dir'   = $os.WindowsDirectory
            $data.'OS Name'          = $os.Caption
            $data.'OS Install Date'  = $os.InstallDate
            $data.'OS Service Pack'  = [string]$os.ServicePackMajorVersion + '.' + $os.ServicePackMinorVersion
        }

        # Scan common TCP ports
        $ports = @{
            'File shares/RPC' = 139
            'File shares'     = 445
            'RDP'             = 3389
        }
        foreach ($service in $ports.Keys) {
            $socket = [System.Net.Sockets.TcpClient]::new()
            try {
                $socket.Connect($computer, $ports.$service)
                $data."Port $($ports.$service) ($service)" = if ($socket.Connected) { 'Open' } else { 'Closed or filtered' }
            } catch {
                $data."Port $($ports.$service) ($service)" = 'Closed or filtered'
            } finally {
                $socket.Close()
            }
        }
    } else {
        $data.'CIM Data Collected' = 'No (no ping reply and -IgnorePing not specified)'
    }

    # Memory detail (also via CIM)
    if ($mem = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $computer -ErrorAction SilentlyContinue) {
        $totalRAM = [Math]::Round($mem.TotalVisibleMemorySize / 1MB, 2)
        $freeRAM  = [Math]::Round($mem.FreePhysicalMemory / 1MB, 2)
        $usedRAM  = [Math]::Round(($mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory) / 1MB, 2)
        $ramPctFree = if ($totalRAM) { [Math]::Round(($freeRAM / $totalRAM) * 100, 2) } else { 0 }

        $data.'Memory - Total RAM GB'           = $totalRAM
        $data.'Memory - RAM Free GB'            = $freeRAM
        $data.'Memory - RAM Used GB'            = $usedRAM
        $data.'Memory - Percentage Free'        = $ramPctFree
        $data.'Memory - TotalVirtualMemorySize' = [Math]::Round($mem.TotalVirtualMemorySize / 1MB, 3)
        $data.'Memory - FreeVirtualMemory'      = [Math]::Round($mem.FreeVirtualMemory / 1MB, 3)
        $data.'Memory - FreeSpaceInPagingFiles' = [Math]::Round($mem.FreeSpaceInPagingFiles / 1MB, 3)
        $data.'NumberofProcesses'               = $mem.NumberOfProcesses
        $data.'NumberOfUsers'                   = $mem.NumberOfUsers
    }

    # Output
    '#' * 80
    'OS Complete Information'
    "Generated $(Get-Date)"
    "Generated from $env:COMPUTERNAME"
    '#' * 80

    $data.GetEnumerator() | Sort-Object Name | Format-Table -AutoSize
    $data.GetEnumerator() | Sort-Object Name | Out-GridView -Title "$computer Information"
}
