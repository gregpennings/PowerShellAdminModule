function ConvertTo-AdminConfigPsd1 {
    <#
    .SYNOPSIS
        (Private) Serializes a hashtable to PowerShell Data File (.psd1) text.

    .DESCRIPTION
        Used by Set-AdminConfig to write override files. Supports string,
        string[]/array, integer, and boolean values -- sufficient for config
        settings. Single quotes in string values are escaped by doubling.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Data
    )

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('# Admin module config override - managed by Set-AdminConfig')
    [void]$sb.AppendLine('@{')
    foreach ($key in ($Data.Keys | Sort-Object)) {
        $value = $Data[$key]
        $rendered =
            if ($value -is [bool]) {
                "`$$($value.ToString().ToLower())"          # $true / $false
            } elseif ($value -is [int] -or $value -is [long] -or $value -is [double]) {
                "$value"
            } elseif ($value -is [System.Array]) {
                ($value | ForEach-Object { "'" + ($_ -replace "'", "''") + "'" }) -join ', '
            } else {
                "'" + ($value -replace "'", "''") + "'"
            }
        [void]$sb.AppendLine("    $key = $rendered")
    }
    [void]$sb.AppendLine('}')
    $sb.ToString()
}
