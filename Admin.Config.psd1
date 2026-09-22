@{
    # Baseline/template settings for the Admin module, tracked in the repo.
    # Keep this file generic -- do NOT put site-specific or sensitive values here
    # (it is public). Personal or per-machine values belong in an untracked
    # override written by Set-AdminConfig (%APPDATA%\Admin or %ProgramData%\Admin),
    # which survives 'git pull'. View the effective settings with Get-AdminConfig.

    # Path to the PsExec executable used by the Enable-* remoting helpers.
    # Override with: Set-AdminConfig -Name PsExecPath -Value '<path-to-psexec>'
    PsExecPath        = 'C:\tools\PowerTools\psexec'

    # Default output directory for generated files
    # (New-FileNameWithTimestamp, Get-VMInfoAllVMs -ExportCsv).
    DefaultExportPath = 'C:\temp'

    # Hyper-V hosts to mount with Connect-HyperVHost (called with no -ComputerName).
    # Keep this empty here -- the actual host names are environment-specific. Set
    # them per-machine/user with:
    #   Set-AdminConfig -Name HyperVHosts -Value @('hv01','hv02','clusternodeA')
    # For failover clusters, list every node; clustered VMs are deduped by VM id.
    HyperVHosts       = @()

    # ----- Entra / Microsoft Graph app registration --------------------------
    # Identity the Entra-facing commands (Get-CredExpiration) authenticate with,
    # app-only, via Connect-AdminGraph. All three must be set for app-only auth;
    # with any of them missing the commands fall back to interactive device-code
    # sign-in as the calling user.
    #
    # These are tenant-specific, so they stay EMPTY here (this file is public)
    # and belong in your untracked override. Create the app registration and
    # certificate, and have all three written for you, with:
    #   .\Scripts\2026-09-22-New-AdminModuleAppRegistration.ps1 -Configure
    # or set them by hand:
    #   Set-AdminConfig -Name EntraTenantId       -Value '<tenant guid>'
    #   Set-AdminConfig -Name EntraClientId       -Value '<app registration guid>'
    #   Set-AdminConfig -Name EntraCertThumbprint -Value '<client cert thumbprint>'
    #
    # The thumbprint is not a secret; the private key it points at (in
    # Cert:\CurrentUser\My) is what must be protected.
    EntraTenantId       = ''
    EntraClientId       = ''
    EntraCertThumbprint = ''
}
