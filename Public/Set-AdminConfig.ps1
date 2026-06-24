function Set-AdminConfig {
    <#
    .SYNOPSIS
        Sets a persistent Admin module configuration value.

    .DESCRIPTION
        Writes a setting to one of the override config files that live OUTSIDE the
        repo, so the value survives every 'git pull':

          -Scope User    (default)  %APPDATA%\Admin\Admin.Config.psd1   (per-user, wins)
          -Scope Machine            %ProgramData%\Admin\Admin.Config.psd1 (per-machine)

        These layer on top of the repo's baseline Admin.Config.psd1. After writing,
        the in-memory configuration is rebuilt so Get-AdminConfig reflects the
        change immediately. This is the Set-PowerCLIConfiguration-style "set it
        once" knob for your environment.

    .PARAMETER Name
        The setting name, e.g. PsExecPath or DefaultExportPath, or any new key you
        want to keep (e.g. a default vCenter list).

    .PARAMETER Value
        The value to store. Strings and string arrays are supported.

    .PARAMETER Scope
        Where to persist: User (per-user, default) or Machine (per-machine).
        Writing Machine scope requires permission to %ProgramData%.

    .EXAMPLE
        Set-AdminConfig -Name DefaultExportPath -Value 'D:\Reports'
        Persists your personal default export path; survives repo pulls.

    .EXAMPLE
        Set-AdminConfig -Name PsExecPath -Value 'C:\tools\psexec.exe' -Scope Machine
        Sets a machine-wide PsExec path override.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        $Value,

        [ValidateSet('User', 'Machine')]
        [string]$Scope = 'User'
    )

    $path = $script:AdminConfigPaths[$Scope]

    # Load existing overrides at this scope (start fresh if none / unreadable)
    $store = @{}
    if (Test-Path -LiteralPath $path) {
        try {
            $existing = Import-PowerShellDataFile -Path $path
            $store = @{} + $existing
        } catch {
            Write-Warning "Could not read existing override '$path'; it will be recreated. $_"
        }
    }

    $store[$Name] = $Value

    $dir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    if ($PSCmdlet.ShouldProcess($path, "Set '$Name'")) {
        try {
            ConvertTo-AdminConfigPsd1 -Data $store | Set-Content -LiteralPath $path -Encoding UTF8
        } catch {
            throw "Failed to write config '$path': $_"
        }
        # Rebuild effective config so precedence (User wins) is recomputed correctly
        Initialize-AdminConfig
        Write-Verbose "Set '$Name' in $Scope scope ($path)."
    }
}
