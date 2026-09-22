<#
.SYNOPSIS
Creates the Entra app registration the Admin module uses for Microsoft Graph,
with certificate (app-only) authentication.

.DESCRIPTION
Stands up everything Get-CredExpiration -- and any future Entra-facing command
in the module -- needs to reach Graph without an interactive sign-in:

  1. A self-signed client certificate in Cert:\CurrentUser\My (unless you supply
     an existing thumbprint with -CertificateThumbprint).
  2. An app registration (single tenant, no redirect URI, no client secret) with
     that certificate as its key credential.
  3. The matching service principal (enterprise application).
  4. App-role (application permission) grants for -Permissions, resolved at run
     time from the tenant's own Microsoft Graph service principal rather than
     from hardcoded GUIDs.
  5. Optionally (-Configure), the resulting tenant/client/thumbprint values
     written into your per-user Admin config.

BLAST RADIUS -- read before running without -WhatIf:
  * Creates a NEW app registration and service principal in your tenant. It
    does not read, modify, or delete any existing application.
  * Grants that new service principal the application permissions listed in
    -Permissions. The default, Application.Read.All, is tenant-wide READ over
    every app registration and service principal -- it cannot change anything.
    Anyone who can use the certificate gains that read access, so protect the
    private key accordingly.
  * Creating the app-role assignment IS the admin consent. There is no separate
    consent prompt and no approval step afterwards.
  * Writes a certificate with an exportable private key into your user
    certificate store.
  * -Configure writes to %APPDATA%\Admin\Admin.Config.psd1 (untracked).

Run it with -WhatIf first to see exactly what would be created.

WHO CAN RUN THIS
You must sign in as a Privileged Role Administrator or Global Administrator:
creating the app-role assignment (step 4) is granting admin consent for an
application permission, which Application Administrator alone cannot do.
Steps 1-3 only need Application Administrator.

The script signs in with the delegated scopes Application.ReadWrite.All and
AppRoleAssignment.ReadWrite.All.

.PARAMETER DisplayName
Display name for the app registration. Default 'Admin PowerShell Module'.

.PARAMETER Permissions
Microsoft Graph application permissions (app roles) to grant. Default
Application.Read.All, which is what Get-CredExpiration requires: it covers
GET /applications and GET /servicePrincipals, including their
passwordCredentials and keyCredentials.

.PARAMETER CertificateThumbprint
Use an existing certificate from Cert:\CurrentUser\My instead of creating a
self-signed one. Its public key is uploaded to the app registration.

.PARAMETER CertificateYears
Lifetime of the generated self-signed certificate, in years. Default 2.

.PARAMETER TenantId
Tenant to sign in to. Defaults to whatever tenant your sign-in resolves to.

.PARAMETER Configure
After creating everything, persist EntraTenantId, EntraClientId and
EntraCertThumbprint via Set-AdminConfig so the module picks them up. Requires
the Admin module to be loaded.

.PARAMETER RenewCertificate
Issue a new certificate and add it to an EXISTING app registration (matched by
-DisplayName, or by -ClientId), leaving the app registration and its permission
grants alone. Use this when the client certificate is nearing expiry.

.PARAMETER ClientId
Application (client) ID of an existing app registration, for -RenewCertificate.

.EXAMPLE
.\2026-09-22-New-AdminModuleAppRegistration.ps1 -WhatIf

Dry run: shows the certificate, app registration, service principal and
permission grants that would be created, and changes nothing.

.EXAMPLE
.\2026-09-22-New-AdminModuleAppRegistration.ps1 -Configure

Creates everything and writes the three settings into the per-user Admin config,
so Get-CredExpiration authenticates app-only on its next run.

.EXAMPLE
.\2026-09-22-New-AdminModuleAppRegistration.ps1 -RenewCertificate -Configure

Issues a replacement certificate for the existing app registration and points
the module at it. Remove the old key credential in the portal once verified.

.NOTES
Requires the Microsoft.Graph.Applications and Microsoft.Graph.Authentication
modules, and Windows (New-SelfSignedCertificate) when generating a certificate.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$DisplayName = 'Admin PowerShell Module',
    [string[]]$Permissions = @('Application.Read.All'),
    [string]$CertificateThumbprint,
    [int]$CertificateYears = 2,
    [string]$TenantId,
    [switch]$Configure,
    [switch]$RenewCertificate,
    [string]$ClientId
)

$ErrorActionPreference = 'Stop'

# Well-known appId of the Microsoft Graph resource application. Constant across
# every tenant; the script still resolves it to the local service principal
# below so a wrong/absent value fails loudly instead of silently.
$GraphAppId = '00000003-0000-0000-c000-000000000000'

foreach ($m in 'Microsoft.Graph.Authentication', 'Microsoft.Graph.Applications') {
    if (-not (Get-Module -ListAvailable -Name $m)) {
        throw "Required module '$m' is not installed. Install it with: Install-Module $m -Scope CurrentUser"
    }
    Import-Module $m -ErrorAction Stop
}

# ---- Sign in -----------------------------------------------------------------
$connectArgs = @{
    Scopes        = @('Application.ReadWrite.All', 'AppRoleAssignment.ReadWrite.All')
    UseDeviceCode = $true
    NoWelcome     = $true
}
if ($TenantId) { $connectArgs.TenantId = $TenantId }

Set-MgGraphOption -DisableLoginByWAM $true
Write-Host 'Signing in to Microsoft Graph (admin consent rights required)...'
Connect-MgGraph @connectArgs

$ctx = Get-MgContext
if (-not $ctx) { throw 'No active Graph context after Connect-MgGraph.' }
Write-Host "Signed in as $($ctx.Account) in tenant $($ctx.TenantId)."

# ---- Resolve the Microsoft Graph service principal and requested app roles ---
# Resolving app roles from the tenant avoids baking permission GUIDs into the
# script, and fails clearly if a permission name is misspelled.
$graphSp = Get-MgServicePrincipal -Filter "appId eq '$GraphAppId'" -ErrorAction Stop |
           Select-Object -First 1
if (-not $graphSp) {
    throw "Could not find the Microsoft Graph service principal (appId $GraphAppId) in this tenant."
}

$appRoles = foreach ($permission in $Permissions) {
    $role = $graphSp.AppRoles |
            Where-Object { $_.Value -eq $permission -and $_.AllowedMemberTypes -contains 'Application' -and $_.IsEnabled }
    if (-not $role) {
        throw "'$permission' is not an enabled Microsoft Graph APPLICATION permission. Check the spelling; delegated-only permissions cannot be granted app-only."
    }
    [PSCustomObject]@{ Name = $permission; Id = $role.Id }
}
Write-Host "Resolved $($appRoles.Count) application permission(s): $($appRoles.Name -join ', ')"

# ---- Locate the existing app registration for -RenewCertificate --------------
$app = $null
$sp  = $null
if ($RenewCertificate) {
    $app = if ($ClientId) {
        Get-MgApplication -Filter "appId eq '$ClientId'" -ErrorAction Stop | Select-Object -First 1
    } else {
        Get-MgApplication -Filter "displayName eq '$DisplayName'" -ErrorAction Stop | Select-Object -First 1
    }
    if (-not $app) {
        $searchedBy = if ($ClientId) { "appId '$ClientId'" } else { "displayName '$DisplayName'" }
        throw "-RenewCertificate was specified but no existing app registration matched. Searched by $searchedBy."
    }
    Write-Host "Renewing certificate for existing app registration '$($app.DisplayName)' ($($app.AppId))."
} else {
    $clash = Get-MgApplication -Filter "displayName eq '$DisplayName'" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($clash) {
        throw "An app registration named '$DisplayName' already exists (appId $($clash.AppId)). Use -DisplayName to pick another name, or -RenewCertificate to add a new certificate to it."
    }
}

# ---- Certificate -------------------------------------------------------------
if ($CertificateThumbprint) {
    $cert = Get-ChildItem -Path 'Cert:\CurrentUser\My' |
            Where-Object { $_.Thumbprint -eq $CertificateThumbprint } |
            Select-Object -First 1
    if (-not $cert) { throw "Certificate '$CertificateThumbprint' not found in Cert:\CurrentUser\My." }
    if (-not $cert.HasPrivateKey) { throw "Certificate '$CertificateThumbprint' has no private key, so it cannot be used to authenticate." }
    Write-Host "Using existing certificate $($cert.Thumbprint) (expires $($cert.NotAfter.ToString('yyyy-MM-dd')))."
} else {
    $subject = "CN=$DisplayName"
    if ($PSCmdlet.ShouldProcess('Cert:\CurrentUser\My', "Create self-signed certificate '$subject' valid $CertificateYears year(s)")) {
        $certParams = @{
            Subject           = $subject
            CertStoreLocation = 'Cert:\CurrentUser\My'
            KeyExportPolicy   = 'Exportable'
            KeySpec           = 'Signature'
            KeyLength         = 2048
            KeyAlgorithm      = 'RSA'
            HashAlgorithm     = 'SHA256'
            NotAfter          = (Get-Date).AddYears($CertificateYears)
        }
        $cert = New-SelfSignedCertificate @certParams
        Write-Host "Created certificate $($cert.Thumbprint) (expires $($cert.NotAfter.ToString('yyyy-MM-dd')))."
    } else {
        Write-Host "WhatIf: would create a self-signed certificate '$subject' in Cert:\CurrentUser\My."
        $cert = $null
    }
}

# Under -WhatIf there is deliberately no certificate and we carry on to show the
# rest of the plan. If the certificate was *declined* at a confirmation prompt,
# stop here rather than going on to create an app registration with no way to
# authenticate to it.
if (-not $cert -and -not $WhatIfPreference) {
    throw 'Certificate creation was declined, so nothing further was created. Re-run and approve the certificate, or pass -CertificateThumbprint to use an existing one.'
}

$keyCredential = if ($cert) {
    @{
        Type        = 'AsymmetricX509Cert'
        Usage       = 'Verify'
        Key         = $cert.RawData
        DisplayName = "CN=$DisplayName"
    }
} else { $null }

# ---- Create (or update) the app registration ---------------------------------
if ($RenewCertificate) {
    if ($keyCredential -and $PSCmdlet.ShouldProcess($app.DisplayName, 'Add new certificate key credential')) {
        # Keep the existing key credentials so the old certificate keeps working
        # until the new one is verified; prune the old one afterwards.
        $existingKeys = @($app.KeyCredentials | ForEach-Object {
            @{ Type = $_.Type; Usage = $_.Usage; Key = $_.Key; DisplayName = $_.DisplayName }
        })
        Update-MgApplication -ApplicationId $app.Id -KeyCredentials ($existingKeys + $keyCredential)
        Write-Host 'Added the new certificate to the app registration.'
    }
    $sp = Get-MgServicePrincipal -Filter "appId eq '$($app.AppId)'" -ErrorAction SilentlyContinue | Select-Object -First 1
} else {
    if ($PSCmdlet.ShouldProcess($DisplayName, 'Create app registration (single tenant, certificate credential, no secret)')) {
        $appParams = @{
            DisplayName    = $DisplayName
            SignInAudience = 'AzureADMyOrg'
            Notes          = 'Used by the Admin PowerShell module (Get-CredExpiration) for app-only Microsoft Graph access.'
        }
        if ($keyCredential) { $appParams.KeyCredentials = @($keyCredential) }
        $app = New-MgApplication @appParams
        Write-Host "Created app registration '$($app.DisplayName)' (appId $($app.AppId))."
    } else {
        Write-Host "WhatIf: would create app registration '$DisplayName' (single tenant, certificate credential, no client secret)."
    }

    if ($app -and $PSCmdlet.ShouldProcess($DisplayName, 'Create service principal (enterprise application)')) {
        $sp = New-MgServicePrincipal -AppId $app.AppId
        Write-Host "Created service principal (objectId $($sp.Id))."
    } elseif (-not $app) {
        Write-Host 'WhatIf: would create the matching service principal.'
    }
}

# ---- Grant the application permissions (this IS the admin consent) -----------
foreach ($role in $appRoles) {
    $target = "service principal '$DisplayName'"
    if ($PSCmdlet.ShouldProcess($target, "Grant Microsoft Graph application permission '$($role.Name)' (admin consent)")) {
        if (-not $sp) { throw 'No service principal available to grant permissions to.' }
        $already = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -ErrorAction SilentlyContinue |
                   Where-Object { $_.AppRoleId -eq $role.Id -and $_.ResourceId -eq $graphSp.Id }
        if ($already) {
            Write-Host "  '$($role.Name)' is already granted; skipping."
            continue
        }
        $assignment = @{
            ServicePrincipalId = $sp.Id
            PrincipalId        = $sp.Id
            ResourceId         = $graphSp.Id
            AppRoleId          = $role.Id
        }
        New-MgServicePrincipalAppRoleAssignment @assignment | Out-Null
        Write-Host "  Granted '$($role.Name)'."
    } else {
        Write-Host "WhatIf: would grant Microsoft Graph application permission '$($role.Name)' (admin consent) to $target."
    }
}

# ---- Persist the settings for the module -------------------------------------
if (-not $app -or -not $cert) {
    Write-Host "`nWhatIf run complete -- nothing was created."
    return
}

Write-Host "`nApp registration ready:"
Write-Host "  EntraTenantId       $($ctx.TenantId)"
Write-Host "  EntraClientId       $($app.AppId)"
Write-Host "  EntraCertThumbprint $($cert.Thumbprint)"

if ($Configure) {
    if (-not (Get-Command Set-AdminConfig -ErrorAction SilentlyContinue)) {
        Write-Warning 'Set-AdminConfig not found -- import the Admin module and set the three values manually.'
    } else {
        Set-AdminConfig -Name EntraTenantId       -Value $ctx.TenantId
        Set-AdminConfig -Name EntraClientId       -Value $app.AppId
        Set-AdminConfig -Name EntraCertThumbprint -Value $cert.Thumbprint
        Write-Host "`nWrote the three settings to your per-user Admin config."
    }
} else {
    Write-Host "`nTo point the module at it:"
    Write-Host "  Set-AdminConfig -Name EntraTenantId       -Value '$($ctx.TenantId)'"
    Write-Host "  Set-AdminConfig -Name EntraClientId       -Value '$($app.AppId)'"
    Write-Host "  Set-AdminConfig -Name EntraCertThumbprint -Value '$($cert.Thumbprint)'"
}

Write-Host "`nApp-role grants can take a minute to propagate before the first app-only call succeeds."
