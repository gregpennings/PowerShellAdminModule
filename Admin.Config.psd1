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
}
