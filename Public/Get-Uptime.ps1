function Get-Uptime {
    <#
    .SYNOPSIS
        Gets OS and last-boot information for one or more computers.

    .DESCRIPTION
        Queries Win32_OperatingSystem via CIM and returns the computer name, OS
        caption, service pack, architecture, and last boot-up time.

    .PARAMETER ComputerName
        One or more computers to query. Defaults to the local computer. Accepts
        pipeline input.

    .EXAMPLE
        Get-Uptime -ComputerName SERVER01

    .EXAMPLE
        'SERVER01','SERVER02' | Get-Uptime

    .OUTPUTS
        PSCustomObject (CSName, Caption, ServicePackMajorVersion, OSArchitecture, LastBootUpTime).
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )
    process {
        foreach ($computer in $ComputerName) {
            Get-CimInstance -ComputerName $computer -ClassName Win32_OperatingSystem |
                Select-Object CSName, Caption, ServicePackMajorVersion, OSArchitecture, LastBootUpTime
        }
    }
}
