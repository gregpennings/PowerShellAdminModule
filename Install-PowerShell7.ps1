<#
.SYNOPSIS
    Installs, upgrades, or reverts Microsoft PowerShell 7 (in-place, via the official
    per-version MSI). Deliberately written in Windows PowerShell 5.1-compatible
    syntax so it can BOOTSTRAP PowerShell 7 on a machine that only has 5.1 -- where
    the Admin module (which now requires 7.0) cannot even load.

.DESCRIPTION
    Standalone companion to the Admin module's Update-PowerShell. It does not depend
    on the module, so run it directly from Windows PowerShell 5.1:

        powershell.exe -ExecutionPolicy Bypass -File .\Install-PowerShell7.ps1

    Behavior:
      - Default          : installs the latest stable 7.x release.
      - -Version x.y.z    : installs that exact version. If it is LOWER than the
                            installed 7.x, the current PowerShell 7 is uninstalled
                            first, then the target is installed (in-place revert).
      - -ListVersions     : lists recent releases and exits (no install, no elevation).
      - -IncludePreview   : include previews in the list, and (with no -Version)
                            install the latest preview instead of latest stable.

    Installs run via msiexec and therefore require an elevated session. PowerShell 7
    upgrades in place at "%ProgramFiles%\PowerShell\7", so there is a single 7.x at a
    time; reverting replaces the current one.

.PARAMETER Version
    Exact version to install, e.g. 7.4.6. Omit to install the latest stable.

.PARAMETER ListVersions
    List recent PowerShell releases and exit. Read-only; no elevation required.

.PARAMETER IncludePreview
    Include preview releases in -ListVersions, and install the latest preview when
    no -Version is given.

.PARAMETER Quiet
    Run msiexec silently (/quiet /norestart) with no UI.

.PARAMETER Count
    How many recent releases to show with -ListVersions (default 15).

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File .\Install-PowerShell7.ps1
    Bootstrap the latest stable PowerShell 7 from Windows PowerShell 5.1.

.EXAMPLE
    .\Install-PowerShell7.ps1 -ListVersions

.EXAMPLE
    .\Install-PowerShell7.ps1 -Version 7.4.6 -Quiet
    Install (or revert to) exactly 7.4.6, silently.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Version,
    [switch]$ListVersions,
    [switch]$IncludePreview,
    [switch]$Quiet,
    [int]$Count = 15
)

$ErrorActionPreference = 'Stop'

# GitHub requires TLS 1.2; Windows PowerShell 5.1 may negotiate lower by default.
[Net.ServicePointManager]::SecurityProtocol = `
    [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$apiUrl  = 'https://api.github.com/repos/PowerShell/PowerShell/releases?per_page=50'
$headers = @{ 'User-Agent' = 'Install-PowerShell7' }

# Normalize a Version to Major.Minor.Build so 7.4.6 and 7.4.6.0 compare equal.
function ConvertTo-MMB {
    param([version]$V)
    [version]('{0}.{1}.{2}' -f $V.Major, [Math]::Max($V.Minor, 0), [Math]::Max($V.Build, 0))
}

function Get-PS7Release {
    $rels = Invoke-RestMethod -Uri $apiUrl -Headers $headers
    if (-not $IncludePreview) { $rels = $rels | Where-Object { -not $_.prerelease } }
    $rels
}

# --- List mode (no elevation needed) -----------------------------------------
if ($ListVersions) {
    Get-PS7Release | Select-Object -First $Count | ForEach-Object {
        New-Object psobject -Property ([ordered]@{
            Version    = ($_.tag_name -replace '^v')
            Prerelease = [bool]$_.prerelease
            Published  = ([datetime]$_.published_at).ToString('yyyy-MM-dd')
        })
    }
    return
}

# --- Resolve target version --------------------------------------------------
if ($Version) {
    $target = ($Version -replace '^v')
} else {
    $rel = Get-PS7Release | Select-Object -First 1
    if (-not $rel) { throw 'Could not determine the latest PowerShell release.' }
    $target = ($rel.tag_name -replace '^v')
}
$targetMMB = ConvertTo-MMB ([version]$target)
Write-Host ("Target PowerShell version: {0}" -f $target) -ForegroundColor Cyan

# --- Elevation check (msiexec) -----------------------------------------------
# Skipped under -WhatIf so the plan can be previewed from a non-elevated session.
if (-not $WhatIfPreference) {
    $wid = [Security.Principal.WindowsIdentity]::GetCurrent()
    $isAdmin = (New-Object Security.Principal.WindowsPrincipal($wid)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        throw 'Installing PowerShell 7 requires an elevated session. Re-run from a prompt started as Administrator.'
    }
}

# --- Detect the installed in-place stable product (for revert/skip) ----------
function Get-InstalledPS7 {
    $keys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    Get-ItemProperty -Path $keys -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like 'PowerShell 7-x64*' -and $_.WindowsInstaller -eq 1 } |
        Select-Object -First 1
}

$installed = Get-InstalledPS7
$installedMMB = $null
if ($installed -and $installed.DisplayVersion) {
    $installedMMB = ConvertTo-MMB ([version]$installed.DisplayVersion)
    Write-Host ("Currently installed: PowerShell 7 {0}" -f $installedMMB) -ForegroundColor Cyan
}

if ($installedMMB -and $installedMMB -eq $targetMMB) {
    Write-Host ("PowerShell 7 {0} is already installed. Nothing to do." -f $target) -ForegroundColor Green
    return
}

# --- Download the per-version MSI --------------------------------------------
$arch    = if ([Environment]::Is64BitOperatingSystem) { 'x64' } else { 'x86' }
$msiName = "PowerShell-$target-win-$arch.msi"
$msiUrl  = "https://github.com/PowerShell/PowerShell/releases/download/v$target/$msiName"
$msiPath = Join-Path $env:TEMP $msiName

Write-Host ("Downloading {0} ..." -f $msiName) -ForegroundColor Cyan
$oldProgress = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'   # speeds up Invoke-WebRequest on 5.1
try {
    Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -Headers $headers
} finally {
    $ProgressPreference = $oldProgress
}

# --- In-place revert: uninstall the newer 7.x first --------------------------
if ($installedMMB -and $installedMMB -gt $targetMMB) {
    if ($PSCmdlet.ShouldProcess("PowerShell 7 $installedMMB", "Uninstall (revert to $target)")) {
        Write-Host ("Reverting: uninstalling PowerShell 7 {0} ..." -f $installedMMB) -ForegroundColor Yellow
        $uninstallArgs = @('/x', $installed.PSChildName, '/quiet', '/norestart')
        $u = Start-Process -FilePath 'msiexec.exe' -ArgumentList $uninstallArgs -Wait -PassThru
        if ($u.ExitCode -ne 0 -and $u.ExitCode -ne 3010) {
            throw ("Uninstall of PowerShell 7 {0} failed (msiexec exit {1})." -f $installedMMB, $u.ExitCode)
        }
    }
}

# --- Install -----------------------------------------------------------------
if ($PSCmdlet.ShouldProcess("PowerShell 7 $target", 'Install via MSI')) {
    $msiArgs = @('/i', ('"' + $msiPath + '"'), '/norestart')
    if ($Quiet) { $msiArgs += '/quiet' }
    Write-Host ("Installing PowerShell 7 {0} ..." -f $target) -ForegroundColor Cyan
    $p = Start-Process -FilePath 'msiexec.exe' -ArgumentList $msiArgs -Wait -PassThru
    if ($p.ExitCode -eq 3010) {
        Write-Host 'Installed. A reboot is required to complete the update.' -ForegroundColor Yellow
    } elseif ($p.ExitCode -ne 0) {
        throw ("Install of PowerShell 7 {0} failed (msiexec exit {1})." -f $target, $p.ExitCode)
    } else {
        Write-Host ("PowerShell 7 {0} installed. Start a NEW pwsh session to use it." -f $target) -ForegroundColor Green
    }
}
