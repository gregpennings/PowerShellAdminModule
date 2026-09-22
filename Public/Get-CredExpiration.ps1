function Get-CredExpiration {
    <#
    .SYNOPSIS
    On-demand credential/certificate expiration checker.

    .DESCRIPTION
    Connects live to Microsoft Graph (no manual CSV export needed) and checks
    App Registrations + Enterprise Applications (Service Principals) for
    expiring or expired secrets/certificates.

    Requires the Application.Read.All Graph permission -- the least-privileged
    one covering both GET /applications and GET /servicePrincipals.

    Authentication (see Connect-AdminGraph) is app-only when the module's app
    registration is configured:

      Set-AdminConfig -Name EntraTenantId       -Value '<tenant guid>'
      Set-AdminConfig -Name EntraClientId       -Value '<app registration guid>'
      Set-AdminConfig -Name EntraCertThumbprint -Value '<client cert thumbprint>'

    Create the app registration and certificate with
    Scripts\2026-09-22-New-AdminModuleAppRegistration.ps1 -Configure.

    Without those settings it falls back to an interactive device-code sign-in
    as you, prompting once per session (a browser window will open).

    .PARAMETER Delegated
    Force the interactive device-code sign-in even when the app registration is
    configured -- useful when your own account can see something the app
    registration's permissions do not cover.

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
    
    .LINK
    https://gregpennings.github.io/PowerShellAdminModule/Get-CredExpiration.html
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
        [switch]$IncludeSummary,
        [switch]$Delegated
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

    # ---- Connect to Graph -----------------------------------------------------
    # Connect-AdminGraph owns the auth decision: app-only with the module's own
    # app registration certificate when it is configured, interactive device code
    # otherwise. Application.Read.All is the least-privileged permission that
    # covers both GET /applications and GET /servicePrincipals below, and exists
    # as both an application and a delegated permission, so the same scope name
    # works for either path.
    Write-Information "Connecting to Microsoft Graph..." -InformationAction Continue
    try {
        $ctx = Connect-AdminGraph -Scopes 'Application.Read.All' -Delegated:$Delegated -ErrorAction Stop
        $how = if ($ctx.AuthType -eq 'AppOnly') { "app-only as $($ctx.AppName)" } else { "as $($ctx.Account)" }
        Write-Information "Connected ($how)." -InformationAction Continue
    } catch {
        Write-Error "Failed to connect to Graph. Error: $_"
        return
    }

    # ---- App Registrations (live) ----
    Write-Information "Pulling App Registrations from Graph..." -InformationAction Continue
    try {
        $apps = Get-MgApplication -All -PageSize 999 -ErrorAction Stop
    } catch {
        Write-Error "Failed to pull App Registrations. Error: $_"
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
    Write-Information "Pulling Enterprise Applications from Graph..." -InformationAction Continue
    try {
        $sps = Get-MgServicePrincipal -All -PageSize 999 -ErrorAction Stop
    } catch {
        Write-Error "Failed to pull Enterprise Applications. Error: $_"
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

        Write-Information "Full results: $CsvOutPath" -InformationAction Continue
        Write-Information "Log updated: $LogPath" -InformationAction Continue
    }

    if ($IncludeSummary) {
        Write-Information "`nExpired: $expiredCount" -InformationAction Continue
        Write-Information "Expiring Soon: $expiringCount" -InformationAction Continue
    }
}

Set-Alias -Name Check-CredExpiration -Value Get-CredExpiration
