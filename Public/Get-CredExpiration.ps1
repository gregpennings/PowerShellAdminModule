function Get-CredExpiration {
    <#
    .SYNOPSIS
    On-demand credential/certificate expiration checker.

    .DESCRIPTION
    Connects live to Microsoft Graph (no manual CSV export needed) and checks
    App Registrations + Enterprise Applications (Service Principals) for
    expiring or expired secrets/certificates.

    Requires: Application.Read.All (already admin-consented as of today)

    On first run in a session, you'll be prompted to sign in via device code
    (a browser window will open).

    .PARAMETER WarningWindowDays
    Days out to flag a credential as "Expiring Soon" (default 30).

    .PARAMETER IncludeAll
    Report on every secret/certificate, not just expired/expiring ones.

    .PARAMETER ExportResults
    Write the log + CSV to -OutDir. Off by default (console output only).

    .PARAMETER OutDir
    Directory for the log/CSV when -ExportResults is used.

    .PARAMETER LookbackDays
    How far into the past to still report already-expired credentials.
    'All' reports every expired credential no matter how long ago it expired.
    A number (default 90) hides expired credentials older than that many days;
    credentials that are OK or expiring soon are never affected by this.

    .PARAMETER IncludeSummary
    Print the Expired / Expiring Soon count summary at the bottom of the console
    output. Off by default.

    .EXAMPLE
    Get-CredExpiration

    .EXAMPLE
    Get-CredExpiration -IncludeAll -ExportResults -WarningWindowDays 45

    .EXAMPLE
    Get-CredExpiration -LookbackDays All -IncludeSummary
    #>
    [CmdletBinding()]
    param(
        [int]$WarningWindowDays = 30,
        [switch]$IncludeAll,
        [switch]$ExportResults,
        [string]$OutDir = "C:\temp\CredExpiration",
        [string]$LogFileName = "expiration_report.log",
        [string]$CsvFileName = "expiration_report.csv",
        [ValidateScript({ $_ -eq 'All' -or $_ -match '^\d+$' }, ErrorMessage = "LookbackDays must be 'All' or a whole number of days.")]
        [string]$LookbackDays = "90",
        [switch]$IncludeSummary
    )

    $LookbackFilterDays = if ($LookbackDays -eq 'All') { $null } else { [int]$LookbackDays }

    if ($ExportResults -and -not (Test-Path $OutDir)) {
        New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
    }
    $LogPath = Join-Path $OutDir $LogFileName
    $CsvOutPath = Join-Path $OutDir $CsvFileName

    $today = Get-Date
    $results = @()

    # Consistent output TypeName so results stay real objects (AppId, CredType, etc.)
    # through the pipeline into things like Renew-Cert / Renew-Secret, instead of
    # being collapsed to formatting-engine objects by a Format-Table call.
    $typeName = 'HCI.CredExpiration.Result'
    Update-TypeData -TypeName $typeName -DefaultDisplayPropertySet Source, AppName, CredType, EndDateTime, DaysUntilExp, Status -Force

    function Get-Status($endDate) {
        $days = ($endDate - $today).Days
        $status = if ($days -lt 0) { "Expired" }
                  elseif ($days -le $WarningWindowDays) { "Expiring Soon" }
                  else { "OK" }
        return @{ Days = $days; Status = $status }
    }

    # ---- Connect to Graph (device code avoids the WAM broker hang; disabling WAM
    #      stops it from corrupting the device-code token on the very next call) ----
    Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
    try {
        Set-MgGraphOption -DisableLoginByWAM $true
        Connect-MgGraph -NoWelcome -UseDeviceCode -ErrorAction Stop
        if (-not (Get-MgContext)) {
            throw "No active Graph context after Connect-MgGraph."
        }
        Write-Host "Connected." -ForegroundColor Green
    } catch {
        Write-Host "Failed to connect to Graph. Error: $_" -ForegroundColor Red
        return
    }

    # ---- App Registrations (live) ----
    Write-Host "Pulling App Registrations from Graph..." -ForegroundColor Cyan
    try {
        $apps = Get-MgApplication -All -PageSize 999 -ErrorAction Stop
    } catch {
        Write-Host "Failed to pull App Registrations. Error: $_" -ForegroundColor Red
        return
    }

    foreach ($app in $apps) {
        foreach ($secret in $app.PasswordCredentials) {
            if ($secret.EndDateTime) {
                $endDate = [datetime]$secret.EndDateTime
                $s = Get-Status $endDate
                $results += [PSCustomObject]@{
                    PSTypeName = $typeName
                    Source = "App Registration"; AppName = $app.DisplayName
                    AppId = $app.AppId; CredType = "Secret"
                    EndDateTime = $endDate; DaysUntilExp = $s.Days; Status = $s.Status
                }
            }
        }
        foreach ($cert in $app.KeyCredentials) {
            if ($cert.EndDateTime) {
                $endDate = [datetime]$cert.EndDateTime
                $s = Get-Status $endDate
                $results += [PSCustomObject]@{
                    PSTypeName = $typeName
                    Source = "App Registration"; AppName = $app.DisplayName
                    AppId = $app.AppId; CredType = "Certificate"
                    EndDateTime = $endDate; DaysUntilExp = $s.Days; Status = $s.Status
                }
            }
        }
    }

    # ---- Enterprise Applications / Service Principals (live) ----
    Write-Host "Pulling Enterprise Applications from Graph..." -ForegroundColor Cyan
    try {
        $sps = Get-MgServicePrincipal -All -PageSize 999 -ErrorAction Stop
    } catch {
        Write-Host "Failed to pull Enterprise Applications. Error: $_" -ForegroundColor Red
        return
    }

    foreach ($sp in $sps) {
        foreach ($secret in $sp.PasswordCredentials) {
            if ($secret.EndDateTime) {
                $endDate = [datetime]$secret.EndDateTime
                $s = Get-Status $endDate
                $results += [PSCustomObject]@{
                    PSTypeName = $typeName
                    Source = "Enterprise Application"; AppName = $sp.DisplayName
                    AppId = $sp.AppId; CredType = "Secret"
                    EndDateTime = $endDate; DaysUntilExp = $s.Days; Status = $s.Status
                }
            }
        }
        foreach ($cert in $sp.KeyCredentials) {
            if ($cert.EndDateTime) {
                $endDate = [datetime]$cert.EndDateTime
                $s = Get-Status $endDate
                $results += [PSCustomObject]@{
                    PSTypeName = $typeName
                    Source = "Enterprise Application"; AppName = $sp.DisplayName
                    AppId = $sp.AppId; CredType = "Certificate"
                    EndDateTime = $endDate; DaysUntilExp = $s.Days; Status = $s.Status
                }
            }
        }
    }

    # ---- Apply lookback window to already-expired credentials ----
    if ($null -ne $LookbackFilterDays) {
        $results = $results | Where-Object { $_.Status -ne "Expired" -or $_.DaysUntilExp -ge (0 - $LookbackFilterDays) }
    }

    # ---- Flag and report ----
    $flagged = if ($IncludeAll) { $results } else { $results | Where-Object { $_.Status -ne "OK" } }
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    $expiredCount = ($results | Where-Object { $_.Status -eq "Expired" }).Count
    $expiringCount = ($results | Where-Object { $_.Status -eq "Expiring Soon" }).Count
    $summary = "[$timestamp] Checked $($results.Count) credentials total (live Graph). Expired: $expiredCount, Expiring Soon: $expiringCount (within $WarningWindowDays days)."

    $flagged | Sort-Object DaysUntilExp

    if ($ExportResults) {
        Add-Content -Path $LogPath -Value $summary
        $flagged | Export-Csv -Path $CsvOutPath -NoTypeInformation

        Write-Host "Full results: $CsvOutPath" -ForegroundColor Green
        Write-Host "Log updated: $LogPath" -ForegroundColor Green
    }

    if ($IncludeSummary) {
        Write-Host "`nExpired: $expiredCount" -ForegroundColor Red
        Write-Host "Expiring Soon: $expiringCount" -ForegroundColor Yellow
    }
}

Set-Alias -Name Check-CredExpiration -Value Get-CredExpiration
