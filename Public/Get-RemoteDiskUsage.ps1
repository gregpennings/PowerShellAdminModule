function Get-RemoteDiskUsage {
    <#
    .SYNOPSIS
        Retrieves file-system disk usage from one or more remote computers.

    .DESCRIPTION
        Connects to the specified computers and reports, for each fixed file-system
        drive, the total size, space used, space free, and percentage used/free.

    .PARAMETER ComputerName
        One or more computers to query. Accepts pipeline input.

    .EXAMPLE
        Get-RemoteDiskUsage -ComputerName Server01

    .EXAMPLE
        'Server01','Server02' | Get-RemoteDiskUsage

    .OUTPUTS
        PSCustomObject per drive (Name, Drive Size (GB), Space Used (GB), % Used,
        Space Free (GB), % Free).

    .NOTES
        Author: Greg Pennings
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$ComputerName
    )
    process {
        try {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                Get-PSDrive -PSProvider FileSystem | Select-Object Name,
                    @{Name = "Drive Size (GB)"; Expression = { [math]::Round(($_.Used + $_.Free) / 1GB, 2) }},
                    @{Name = "Space Used (GB)"; Expression = { [math]::Round($_.Used / 1GB, 2) }},
                    @{Name = "% Used";          Expression = { "$([math]::Round(($_.Used / ($_.Used + $_.Free)) * 100, 2))%" }},
                    @{Name = "Space Free (GB)"; Expression = { [math]::Round($_.Free / 1GB, 2) }},
                    @{Name = "% Free";          Expression = { "$([math]::Round(($_.Free / ($_.Used + $_.Free)) * 100, 2))%" }}
            }
        } catch {
            Write-Error "Failed to retrieve disk usage information: $_"
        }
    }
}
