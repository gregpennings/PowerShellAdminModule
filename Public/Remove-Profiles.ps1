function Remove-Profiles {
    <#
    .SYNOPSIS
        Removes non-loaded, non-special user profiles from a computer.

    .DESCRIPTION
        Two ways to use this:
          - Standalone: pass -ComputerName and it queries and removes every
            non-loaded, non-special Win32_UserProfile on that computer itself
            (same behavior as the old Remove-ProfilesFromRemoteComputer).
          - Piped: pipe Win32_UserProfile instances in (e.g. from Get-Profiles,
            optionally filtered first) and only those exact profiles are removed.
        This permanently removes the profile(s), including on-disk data.
        Supports -WhatIf / -Confirm and prompts before each deletion by default.

    .PARAMETER ComputerName
        The computer to clean up. Defaults to the local computer. Ignored when
        profiles are piped in.

    .PARAMETER InputObject
        A Win32_UserProfile CIM instance to remove, typically piped in from
        Get-Profiles.

    .EXAMPLE
        Remove-Profiles -ComputerName SERVER01 -WhatIf
        Shows which profiles would be removed without deleting them.

    .EXAMPLE
        Remove-Profiles -ComputerName SERVER01 -Confirm:$false
        Removes every candidate profile on SERVER01 without prompting.

    .EXAMPLE
        Get-Profiles -ComputerName SERVER01 | Where-Object { $_.LastUseTime -lt (Get-Date).AddDays(-90) } | Remove-Profiles
        Removes only the profiles unused for 90+ days.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'ByComputerName')]
    param(
        [Parameter(ParameterSetName = 'ByComputerName')]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(ParameterSetName = 'ByPipeline', Mandatory, ValueFromPipeline)]
        [Microsoft.Management.Infrastructure.CimInstance]$InputObject
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByPipeline') {
            if ($PSCmdlet.ShouldProcess("$($InputObject.LocalPath) on $($InputObject.PSComputerName)", 'Remove user profile')) {
                Remove-CimInstance -InputObject $InputObject
            }
            return
        }

        $session = New-CimSession -ComputerName $ComputerName
        try {
            Get-CimInstance -CimSession $session -Query "SELECT * FROM Win32_UserProfile WHERE Loaded = FALSE AND Special = FALSE" |
                ForEach-Object {
                    if ($PSCmdlet.ShouldProcess("$($_.LocalPath) on $ComputerName", 'Remove user profile')) {
                        Remove-CimInstance -InputObject $_
                    }
                }
        } finally {
            Remove-CimSession $session
        }
    }
}

Set-Alias -Name Remove-ProfilesFromRemoteComputer -Value Remove-Profiles
