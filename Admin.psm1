# Admin module loader
#
# Each function lives in its own file:
#   Public\   - functions exported to the user (callable from the prompt)
#   Private\  - internal helpers, dot-sourced but NOT exported
#
# See CHANGELOG.md for version history.

# Required at load time by some functions (e.g. Out-GridView / WinForms usage)
Add-Type -AssemblyName System.Windows.Forms

# ----- Module configuration -------------------------------------------------
# Settings are layered, lowest precedence first; later files override earlier:
#   1. Repo Admin.Config.psd1   - org/baseline defaults (tracked, deploys via pull)
#   2. ProgramData override     - per-machine settings (survives git pull)
#   3. APPDATA override         - per-user settings, win over everything (survives pull)
# Manage the override files with Set-AdminConfig; view the merged result with
# Get-AdminConfig. The actual merge runs (Initialize-AdminConfig) after the
# function files are dot-sourced below.
$script:AdminConfigPaths = [ordered]@{
    Repo    = Join-Path $PSScriptRoot 'Admin.Config.psd1'
    Machine = Join-Path $env:ProgramData 'Admin\Admin.Config.psd1'
    User    = Join-Path $env:APPDATA  'Admin\Admin.Config.psd1'
}
$script:AdminConfig = @{}

$public  = @(Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public\*.ps1')  -ErrorAction SilentlyContinue)
$private = @(Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private\*.ps1') -ErrorAction SilentlyContinue)

# Dot-source private helpers first, then public functions
foreach ($file in ($private + $public)) {
    try {
        . $file.FullName
    } catch {
        Write-Error "Failed to import function file '$($file.FullName)': $_"
    }
}

# Build the effective configuration by merging all layers (Private helper)
Initialize-AdminConfig

# Export the public functions plus all module-defined aliases (whois, plus the
# backward-compat aliases for renamed functions). The manifest's AliasesToExport
# is the authoritative gate on which of these are actually exposed.
Export-ModuleMember -Function $public.BaseName -Alias '*'
