function Get-AdminConfig {
    <#
    .SYNOPSIS
        Returns the effective Admin module configuration.

    .DESCRIPTION
        Shows the merged, effective settings the module uses (PsExec path,
        privileged account, domain controller, AD search base, RD session prefix,
        default export path, plus any custom keys you have added).

        Settings are layered, later overriding earlier:
          1. Repo Admin.Config.psd1        (baseline, deploys via git pull)
          2. %ProgramData%\Admin\...psd1   (per-machine override)
          3. %APPDATA%\Admin\...psd1       (per-user override, wins)

        Use Set-AdminConfig to persist overrides. Use -ListPaths to see the layer
        file locations and which ones currently exist.

    .PARAMETER ListPaths
        Instead of the settings, return the config layer files and whether each
        exists, in precedence order.

    .EXAMPLE
        Get-AdminConfig
        Lists the effective settings.

    .EXAMPLE
        (Get-AdminConfig).PsExecPath
        Returns just the configured PsExec path.

    .EXAMPLE
        Get-AdminConfig -ListPaths
        Shows the Repo / Machine / User config file paths and which exist.
    #>
    [CmdletBinding()]
    param(
        [switch]$ListPaths
    )

    if ($ListPaths) {
        foreach ($scope in $script:AdminConfigPaths.Keys) {
            $path = $script:AdminConfigPaths[$scope]
            [PSCustomObject]@{
                Scope  = $scope
                Path   = $path
                Exists = Test-Path -LiteralPath $path
            }
        }
        return
    }

    [PSCustomObject]$script:AdminConfig
}
