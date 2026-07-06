<#
.SYNOPSIS
Generates a timestamped folder and returns it as a System.IO.DirectoryInfo object.

.DESCRIPTION
Creates a folder in the format: yyyyMMddHHmm[ss].Subject, inside the given parent path.
Ensures the parent path exists. Optionally appends a numeric suffix if the folder already exists.
Returns a DirectoryInfo object for easy access to name, path, and full path.

.PARAMETER Subject
The subject or label to include in the folder name. Defaults to 'export'.

.PARAMETER Path
The parent directory in which to create the timestamped folder. Defaults to 'C:\temp'.

.PARAMETER AppendIfExists
If specified, appends a numeric suffix (e.g., _1, _2) to avoid colliding with an existing folder.

.PARAMETER IncludeSeconds
If specified, includes seconds in the timestamp (format: yyyyMMddHHmmss).

.EXAMPLE
$folder = New-FolderNameWithTimestamp -Subject "GPOsByName"
$folder.FullName

Creates and returns a folder like C:\temp\202507171600.GPOsByName.

.EXAMPLE
New-FolderNameWithTimestamp -Subject "Snapshots" -Path "D:\logs" -IncludeSeconds -Verbose

Creates a folder with seconds included in the timestamp and outputs verbose details.

.NOTES
Author: You
Module: Admin

.ERROR CODES
1001 - Failed to create the parent or timestamped folder.
1002 - Failed to generate a unique folder name after multiple attempts.
#>

function New-FolderNameWithTimestamp {
    [CmdletBinding()]
    [OutputType([System.IO.DirectoryInfo])]
    param (
        [string]$Subject = "export",
        [string]$Path = $script:AdminConfig.DefaultExportPath,
        [switch]$AppendIfExists,
        [switch]$IncludeSeconds
    )

    Write-Verbose "Validating or creating parent path: $Path"
    if (-not (Test-Path $Path)) {
        try {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            Write-Verbose "Created parent directory: $Path"
        } catch {
            throw [System.Exception]::new("Error 1001: Failed to create or access path: $Path")
        }
    }

    $format = if ($IncludeSeconds) { "yyyyMMddHHmmss" } else { "yyyyMMddHHmm" }
    $timestamp = Get-Date -Format $format
    $baseName = "$timestamp.$Subject"
    $folderName = $baseName
    $fullPath = Join-Path -Path $Path -ChildPath $folderName

    Write-Verbose "Generated base folder name: $folderName"

    if ($AppendIfExists -and (Test-Path $fullPath)) {
        Write-Verbose "Folder already exists. Attempting to append numeric suffix..."
        $counter = 1
        do {
            $folderName = "$baseName" + "_$counter"
            $fullPath = Join-Path -Path $Path -ChildPath $folderName
            Write-Verbose "Trying: $folderName"
            $counter++
            if ($counter -gt 100) {
                throw [System.Exception]::new("Error 1002: Failed to generate a unique folder name after 100 attempts.")
            }
        } while (Test-Path $fullPath)
        Write-Verbose "Resolved unique folder name: $folderName"
    }

    try {
        Write-Verbose "Creating folder at: $fullPath"
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
    } catch {
        throw [System.Exception]::new("Error 1001: Failed to create the timestamped folder at: $fullPath")
    }

    return [System.IO.DirectoryInfo]::new($fullPath)
}
