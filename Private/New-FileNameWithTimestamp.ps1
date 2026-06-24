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
        [string]$Path = $script:AdminConfig.DefaultExportPath,
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
