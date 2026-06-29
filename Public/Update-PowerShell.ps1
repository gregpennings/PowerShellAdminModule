Function Update-PowerShell {
    <#
    .SYNOPSIS
        Updates PowerShell 7 to the latest release using the recommended installer,
        with a version check, an elevation check, and -WhatIf support.

    .DESCRIPTION
        A guard-railed wrapper around the established update methods:

          - Looks up the latest release and SKIPS the update if the running version
            is already current (override with -Force).
          - Prefers winget (Microsoft's recommended installer on Windows) when it is
            available; otherwise falls back to the official bootstrap script
            'https://aka.ms/install-powershell.ps1 -UseMSI' -- the long-standing
            manual method. Force the MSI path explicitly with -UseMSI.
          - The MSI path requires an elevated session (the machine-wide install needs
            administrator rights); the function checks and fails fast if you are not
            elevated rather than letting the MSI silently no-op.
          - Installs software, so it supports -WhatIf/-Confirm and defaults to
            ConfirmImpact High (it prompts before changing anything).

        For a specific version (including reverting to an older 7.x) or to list recent
        releases, -Version / -ListVersions delegate to the standalone, in-place MSI
        installer shipped alongside the module (Install-PowerShell7.ps1). That same
        script can BOOTSTRAP PowerShell 7 from Windows PowerShell 5.1, where this
        module cannot load -- run it directly there.

        You are updating the pwsh you launch NEXT -- the current session keeps its
        version until you start a new one.

    .PARAMETER Version
        Install (or revert to) an exact version, e.g. 7.4.6. Delegates to
        Install-PowerShell7.ps1 (in-place MSI). Skips the "already latest" check.

    .PARAMETER ListVersions
        List recent PowerShell releases and return, without installing anything.

    .PARAMETER UseMSI
        Force the install-powershell.ps1 + MSI path even when winget is available.
        (Ignored with -Version, which always uses the per-version MSI installer.)

    .PARAMETER Preview
        Install the latest preview build instead of the latest stable. With
        -ListVersions, include preview releases in the list.

    .PARAMETER Force
        Install even if the running version already matches the latest release.

    .PARAMETER Quiet
        Run the installer silently (no UI).

    .EXAMPLE
        Update-PowerShell
        Updates to the latest stable release if a newer one exists; otherwise reports
        that you are current.

    .EXAMPLE
        Update-PowerShell -WhatIf
        Shows the method and target version that would be used, without installing.

    .EXAMPLE
        Update-PowerShell -UseMSI -Quiet
        Forces the official MSI bootstrap (your proven manual method) and installs silently.

    .EXAMPLE
        Update-PowerShell -ListVersions
        Lists recent PowerShell releases.

    .EXAMPLE
        Update-PowerShell -Version 7.4.6
        Installs (or reverts to) exactly 7.4.6 via the in-place MSI installer.

    .NOTES
        Equivalent manual one-liner (what -UseMSI runs under the hood):
            Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI"
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [string]$Version,
        [switch]$ListVersions,
        [switch]$UseMSI,
        [switch]$Preview,
        [switch]$Force,
        [switch]$Quiet
    )

    # --- Specific-version / listing: delegate to the standalone MSI installer ---
    # It ships beside the module (repo root => one level up from Public\) and is the
    # single source of truth for per-version installs and reverts.
    if ($Version -or $ListVersions) {
        $installer = Join-Path (Split-Path -Parent $PSScriptRoot) 'Install-PowerShell7.ps1'
        if (-not (Test-Path -LiteralPath $installer)) {
            throw "Install-PowerShell7.ps1 not found next to the module ('$installer')."
        }

        if ($ListVersions) {
            & $installer -ListVersions -IncludePreview:$Preview
            return
        }

        if ($PSCmdlet.ShouldProcess("PowerShell (v$Version)", 'Install via Install-PowerShell7.ps1')) {
            & $installer -Version $Version -Quiet:$Quiet
        }
        return
    }

    # --- Current vs latest ---------------------------------------------------
    $current = $PSVersionTable.PSVersion
    Write-Verbose "Running session: PowerShell $current"

    # Best-effort: a failed lookup shouldn't block an explicit update request.
    $latest = $null
    if (-not $Preview) {
        try {
            $rel = Invoke-RestMethod -Uri 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest' `
                -Headers @{ 'User-Agent' = 'Update-PowerShell' } -ErrorAction Stop
            $latest = [version]($rel.tag_name -replace '^v')
            Write-Verbose "Latest stable release: $latest"
        } catch {
            Write-Warning "Could not determine the latest release ($($_.Exception.Message)). Proceeding without a version check."
        }
    }

    if ($latest -and -not $Force -and $current -ge $latest) {
        Write-Host "PowerShell is already current ($current >= $latest). Use -Force to reinstall." -ForegroundColor Green
        return
    }

    $target = if ($Preview) { 'latest preview' } elseif ($latest) { "v$latest" } else { 'latest stable' }

    # --- Choose method -------------------------------------------------------
    $wingetAvailable = [bool](Get-Command winget -ErrorAction SilentlyContinue)
    $method = if ($UseMSI -or -not $wingetAvailable) { 'MSI' } else { 'Winget' }

    # Enforce elevation only for a real run; -WhatIf stays side-effect-free so the
    # MSI path can still be previewed from a non-elevated session.
    if ($method -eq 'MSI' -and -not $WhatIfPreference) {
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
            IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            throw "The MSI update path requires an elevated session. Re-run from a PowerShell started as Administrator, or install winget."
        }
    }

    if (-not $PSCmdlet.ShouldProcess("PowerShell ($target)", "Update via $method")) { return }

    # --- Execute -------------------------------------------------------------
    switch ($method) {
        'Winget' {
            $id = if ($Preview) { 'Microsoft.PowerShell.Preview' } else { 'Microsoft.PowerShell' }
            $wgArgs = @('install', '--id', $id, '--source', 'winget',
                        '--accept-source-agreements', '--accept-package-agreements')
            if ($Quiet) { $wgArgs += '--silent' }
            Write-Verbose "winget $($wgArgs -join ' ')"
            & winget @wgArgs
        }
        'MSI' {
            # Official bootstrap installer (https://aka.ms/install-powershell.ps1).
            $installArgs = '-UseMSI'
            if ($Preview) { $installArgs += ' -Preview' }
            if ($Quiet)   { $installArgs += ' -Quiet' }
            $script = Invoke-RestMethod -Uri 'https://aka.ms/install-powershell.ps1' -ErrorAction Stop
            Invoke-Expression "& { $script } $installArgs"
        }
    }

    Write-Host "Update via $method finished. Start a NEW pwsh session to use the updated version." -ForegroundColor Cyan
}
