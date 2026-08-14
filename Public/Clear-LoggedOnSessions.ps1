function Clear-LoggedOnSessions {
    <#
    .SYNOPSIS
        Logs off user sessions on a remote computer.

    .DESCRIPTION
        Two ways to use this:
          - Standalone: pass -ComputerName and it enumerates every logged-on
            session on that computer (via quser). By default (-Select is on)
            it shows them in a grid view (Out-GridView) so you pick which ones
            to log off. Pass -Select:$false to log off every session without
            the picker.
          - Piped: pipe session objects in (e.g. from Get-LoggedOnSessions,
            optionally filtered first) and only those exact sessions are
            logged off.

        Handles both RDP-named sessions (rdp-tcp#NN, via 'logoff' on the host) and
        numeric session IDs (via Invoke-RDUserLogoff).

        Supports -WhatIf / -Confirm. Use -WhatIf to preview which sessions would be
        logged off before committing -- recommended with -Select:$false.

    .PARAMETER ComputerName
        The remote computer whose sessions will be logged off. Mandatory (there is
        no local default) to avoid accidentally logging everyone off this machine.
        Ignored when sessions are piped in.

    .PARAMETER Select
        Show a grid view of the sessions and log off only the ones you select.
        Defaults to $true. Pass -Select:$false to log off every session on the
        computer without the picker. Ignored when sessions are piped in.

    .PARAMETER InputObject
        A session object to log off, typically piped in from Get-LoggedOnSessions.
        Each object's own ComputerName property is used as the logoff target, so
        piped sessions from different computers are each sent to the right host.

    .EXAMPLE
        Clear-LoggedOnSessions -ComputerName RDS01
        Opens a grid view (Out-GridView) listing every session on RDS01; logs off only
        the ones you pick and click OK.

    .EXAMPLE
        Clear-LoggedOnSessions -ComputerName RDS01 -Select:$false
        Logs off ALL sessions on RDS01, no picker.

    .EXAMPLE
        Clear-LoggedOnSessions -ComputerName RDS01 -Select:$false -WhatIf
        Shows which sessions would be logged off, without doing it.

    .EXAMPLE
        Get-LoggedOnSessions -ComputerName RDS01 -Select | Clear-LoggedOnSessions
        Picks sessions from a grid view in Get-LoggedOnSessions, then logs off exactly
        those -- Clear-LoggedOnSessions logs off whatever it receives on the pipeline
        without showing its own picker. Each piped session carries its own
        ComputerName, so this also works if the piped sessions span more than one
        computer.

    .EXAMPLE
        Get-LoggedOnSessions -ComputerName RDS01 | Where-Object State -eq 'Disc' | Clear-LoggedOnSessions
        Logs off only the disconnected sessions on RDS01.

    .LINK
    https://gregpennings.github.io/PowerShellAdminModule/Clear-LoggedOnSessions.html
#>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ByComputerName')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidDefaultValueSwitchParameter', 'Select',
        Justification = 'Defaulting to the safer grid-view picker is intentional; pass -Select:$false to clear all sessions.')]
    param(
        [Parameter(ParameterSetName = 'ByComputerName', Mandatory = $true)]
        [Alias('RemoteComputerName')]
        [string]$ComputerName,

        [Parameter(ParameterSetName = 'ByComputerName')]
        [switch]$Select = $true,

        [Parameter(ParameterSetName = 'ByPipeline', Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$InputObject
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'ByPipeline') {
            $target = "$($InputObject.UserName) (session $($InputObject.SessionID)) on $($InputObject.ComputerName)"
            if ($PSCmdlet.ShouldProcess($target, "Log off")) {
                Invoke-SessionLogoff -ComputerName $InputObject.ComputerName -SessionID $InputObject.SessionID
            }
            return
        }

        # Get the list of logged-on sessions
        $users = quser /server:$ComputerName 2>$null | ConvertFrom-QuserOutput

        if (-not $users) {
            Write-Host "No logged-on sessions found on $ComputerName."
            return
        }

        # Choose which sessions to log off
        if ($Select) {
            $targets = $users | Out-GridView -Title "Select sessions to log off on $ComputerName" -PassThru
            if (-not $targets) {
                Write-Host "No sessions selected."
                return
            }
        } else {
            $targets = $users
        }

        # Log off the chosen sessions
        foreach ($user in $targets) {
            $target = "$($user.UserName) (session $($user.SessionID)) on $ComputerName"
            if ($PSCmdlet.ShouldProcess($target, "Log off")) {
                Invoke-SessionLogoff -ComputerName $ComputerName -SessionID $user.SessionID
            }
        }
    }
} #End Clear-LoggedOnSessions
