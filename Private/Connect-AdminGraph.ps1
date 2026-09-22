function Connect-AdminGraph {
    <#
    .SYNOPSIS
        (Private) Establishes the Microsoft Graph connection used by the
        module's Entra-facing functions.

    .DESCRIPTION
        Single sign-in path for every command that talks to Entra, so the auth
        method lives in one place instead of being re-implemented per command.

        Preferred path is app-only (client credentials) against the module's own
        app registration, authenticating with a certificate. It needs three
        settings, read from the merged Admin configuration:

          EntraTenantId        directory (tenant) ID
          EntraClientId        application (client) ID of the app registration
          EntraCertThumbprint  thumbprint of the client certificate

        These are environment-specific, so they belong in the untracked override
        rather than the public repo config -- set them with Set-AdminConfig, or
        let Scripts\2026-09-22-New-AdminModuleAppRegistration.ps1 -Configure
        write them for you after it creates the app registration.

        If those settings are missing, or -Delegated is used, it falls back to
        the previous behaviour: an interactive device-code sign-in as the calling
        user. Device code (rather than the WAM broker) is deliberate -- the
        broker hangs here, and leaving WAM enabled corrupts the device-code token
        on the very next call.

        An existing usable connection is reused rather than re-authenticated, so
        calling this from several functions in one session prompts at most once.

    .PARAMETER Scopes
        Delegated scopes to request when falling back to interactive sign-in.
        Ignored for app-only, where the effective permissions are the app roles
        consented to the app registration. Defaults to Application.Read.All.

    .PARAMETER Delegated
        Skip app-only and sign in interactively as the calling user, even when
        the app-registration settings are present. Useful when the app
        registration lacks a permission your own account holds.

    .PARAMETER Force
        Disconnect and re-authenticate even if there is already a usable context.

    .OUTPUTS
        The active Microsoft Graph context (Get-MgContext).

    .EXAMPLE
        Connect-AdminGraph -Scopes 'Application.Read.All'
    #>
    [CmdletBinding()]
    param(
        [string[]]$Scopes = @('Application.Read.All'),
        [switch]$Delegated,
        [switch]$Force
    )

    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "The Microsoft.Graph.Authentication module is not installed. Install it with: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser"
    }
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

    $cfg         = Get-AdminConfig
    $tenantId    = $cfg.EntraTenantId
    $clientId    = $cfg.EntraClientId
    $thumbprint  = $cfg.EntraCertThumbprint
    $useAppOnly  = -not $Delegated -and $tenantId -and $clientId -and $thumbprint

    # ---- Reuse an existing usable context ----------------------------------
    # Only reuse a context that matches the mode we were asked for; a leftover
    # delegated context must not silently satisfy an app-only request.
    $existing = Get-MgContext
    if ($existing -and -not $Force) {
        $contextMatches = if ($useAppOnly) {
            $existing.AuthType -eq 'AppOnly' -and $existing.ClientId -eq $clientId
        } else {
            $existing.AuthType -ne 'AppOnly'
        }
        if ($contextMatches) {
            Write-Verbose "Reusing existing Graph context ($($existing.AuthType), client $($existing.ClientId))."
            return $existing
        }
    }
    if ($existing) { Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null }

    # ---- App-only, certificate ---------------------------------------------
    if ($useAppOnly) {
        $cert = Get-ChildItem -Path 'Cert:\CurrentUser\My', 'Cert:\LocalMachine\My' -ErrorAction SilentlyContinue |
                Where-Object { $_.Thumbprint -eq $thumbprint } |
                Select-Object -First 1

        if (-not $cert) {
            throw "Certificate with thumbprint '$thumbprint' (EntraCertThumbprint) was not found in Cert:\CurrentUser\My or Cert:\LocalMachine\My. Re-run the app-registration setup script, or point EntraCertThumbprint at a certificate this account can read."
        }
        if (-not $cert.HasPrivateKey) {
            throw "Certificate '$thumbprint' has no private key in this store, so it cannot be used to authenticate. Import the PFX, or re-run the setup script."
        }
        if ($cert.NotAfter -lt (Get-Date)) {
            throw "The Graph client certificate '$thumbprint' expired on $($cert.NotAfter.ToString('yyyy-MM-dd')). Re-run the setup script with -RenewCertificate to issue a new one."
        }
        if ($cert.NotAfter -lt (Get-Date).AddDays(30)) {
            Write-Warning "The Graph client certificate expires on $($cert.NotAfter.ToString('yyyy-MM-dd')) -- renew it with the setup script's -RenewCertificate switch."
        }

        Write-Verbose "Connecting to Graph app-only as client $clientId in tenant $tenantId."
        Connect-MgGraph -TenantId $tenantId -ClientId $clientId -Certificate $cert -NoWelcome -ErrorAction Stop

        $ctx = Get-MgContext
        if (-not $ctx) { throw "No active Graph context after app-only Connect-MgGraph." }
        return $ctx
    }

    # ---- Delegated fallback (interactive device code) -----------------------
    if (-not $Delegated) {
        Write-Verbose "App-registration settings incomplete (EntraTenantId/EntraClientId/EntraCertThumbprint); falling back to interactive sign-in."
    }

    Set-MgGraphOption -DisableLoginByWAM $true
    $connectArgs = @{
        Scopes        = $Scopes
        UseDeviceCode = $true
        NoWelcome     = $true
        ErrorAction   = 'Stop'
    }
    # Sign in through our own app registration when we know its identity, so the
    # sign-in is auditable to this module rather than to the shared first-party
    # "Microsoft Graph Command Line Tools" app.
    if ($clientId) { $connectArgs.ClientId = $clientId }
    if ($tenantId) { $connectArgs.TenantId = $tenantId }

    Connect-MgGraph @connectArgs

    $ctx = Get-MgContext
    if (-not $ctx) { throw "No active Graph context after Connect-MgGraph." }
    return $ctx
}
