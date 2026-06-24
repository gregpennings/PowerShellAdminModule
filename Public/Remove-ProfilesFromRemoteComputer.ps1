function Remove-ProfilesFromRemoteComputer {
    <#
    .SYNOPSIS
        Removes non-loaded, non-special user profiles from a computer.

    .DESCRIPTION
        Finds Win32_UserProfile instances that are not loaded and not special, then
        deletes them. This permanently removes those user profiles (including their
        on-disk data) from the target. Supports -WhatIf / -Confirm and prompts
        before each deletion by default.

    .PARAMETER ComputerName
        The computer to clean up. Defaults to the local computer.

    .EXAMPLE
        Remove-ProfilesFromRemoteComputer -ComputerName SERVER01 -WhatIf
        Shows which profiles would be removed without deleting them.

    .EXAMPLE
        Remove-ProfilesFromRemoteComputer -ComputerName SERVER01 -Confirm:$false
        Removes the candidate profiles without prompting.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )

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
