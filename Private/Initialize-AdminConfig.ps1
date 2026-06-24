function Initialize-AdminConfig {
    <#
    .SYNOPSIS
        (Private) Rebuilds $script:AdminConfig by merging all config layers.

    .DESCRIPTION
        Loads each file in $script:AdminConfigPaths in order (Repo -> Machine ->
        User) and merges them, so later layers override earlier ones. Called at
        module import and again by Set-AdminConfig after it writes a layer.
    #>
    [CmdletBinding()]
    param()

    $merged = @{}
    foreach ($path in $script:AdminConfigPaths.Values) {
        if (Test-Path -LiteralPath $path) {
            try {
                $loaded = Import-PowerShellDataFile -Path $path
                foreach ($key in $loaded.Keys) { $merged[$key] = $loaded[$key] }
            } catch {
                Write-Warning "Failed to load Admin config '$path': $_"
            }
        }
    }

    if ($merged.Count -eq 0) {
        Write-Warning "No Admin configuration found. Looked in: $($script:AdminConfigPaths.Values -join '; ')"
    }

    $script:AdminConfig = $merged
}
