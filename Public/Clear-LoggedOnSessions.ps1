function Clear-LoggedOnSessions {
    <#
    .SYNOPSIS
        Logs off user sessions on a remote computer.

    .DESCRIPTION
        Two ways to use this:
          - Standalone: pass -ComputerName and it enumerates every logged-on
            session on that computer (via quser) and logs them all off. Use
            -Select to instead choose specific sessions interactively from a
            grid view (Out-GridView).
          - Piped: pipe session objects in (e.g. from Get-LoggedOnSessions,
            optionally filtered first) and only those exact sessions are
            logged off.

        Handles both RDP-named sessions (rdp-tcp#NN, via 'logoff' on the host) and
        numeric session IDs (via Invoke-RDUserLogoff).

        Supports -WhatIf / -Confirm. Use -WhatIf to preview which sessions would be
        logged off before committing -- recommended with the clear-all default.

    .PARAMETER ComputerName
        The remote computer whose sessions will be logged off. Mandatory (there is
        no local default) to avoid accidentally logging everyone off this machine.
        Ignored when sessions are piped in.

    .PARAMETER Select
        Show a grid view of the sessions and log off only the ones you select,
        instead of logging off every session. Ignored when sessions are piped in.

    .PARAMETER InputObject
        A session object to log off, typically piped in from Get-LoggedOnSessions.

    .EXAMPLE
        Clear-LoggedOnSessions -ComputerName RDS01
        Logs off ALL sessions on RDS01.

    .EXAMPLE
        Clear-LoggedOnSessions -ComputerName RDS01 -WhatIf
        Shows which sessions would be logged off, without doing it.

    .EXAMPLE
        Clear-LoggedOnSessions -ComputerName RDS01 -Select
        Lists the sessions in a grid view; logs off only the ones you pick.

    .EXAMPLE
        Get-LoggedOnSessions -ComputerName RDS01 | Where-Object State -eq 'Disc' | Clear-LoggedOnSessions
        Logs off only the disconnected sessions on RDS01.
    #>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ByComputerName')]
    param(
        [Parameter(ParameterSetName = 'ByComputerName', Mandatory = $true)]
        [Alias('RemoteComputerName')]
        [string]$ComputerName,

        [Parameter(ParameterSetName = 'ByComputerName')]
        [switch]$Select,

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
