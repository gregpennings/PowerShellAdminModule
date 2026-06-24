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
