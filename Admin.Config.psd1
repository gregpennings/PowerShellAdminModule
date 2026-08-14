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

    # How old (in minutes) the Get-VMInfo cache can get before a cached read
    # warns you to refresh it. Informational only -- it does not expire or
    # delete the cache, and does not block the read; pass -Live for a
    # real-time query, or run Update-VMInfoCache to rebuild it.
    # Override with: Set-AdminConfig -Name VMInfoCacheMaxAgeMinutes -Value 60
    VMInfoCacheMaxAgeMinutes = 240
}
