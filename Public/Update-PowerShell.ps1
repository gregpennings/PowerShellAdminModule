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

        You are updating the pwsh you launch NEXT -- the current session keeps its
        version until you start a new one.

    .PARAMETER UseMSI
        Force the install-powershell.ps1 + MSI path even when winget is available.

    .PARAMETER Preview
        Install the latest preview build instead of the latest stable.

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

    .NOTES
        Equivalent manual one-liner (what -UseMSI runs under the hood):
            Invoke-Expression "& { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI"
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [switch]$UseMSI,
        [switch]$Preview,
        [switch]$Force,
        [switch]$Quiet
    )

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
