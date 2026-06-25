function Clear-LoggedOnSessions {
    <#
    .SYNOPSIS
        Logs off user sessions on a remote computer.

    .DESCRIPTION
        Enumerates logged-on sessions on the target computer (via quser) and logs
        them off. By default ALL sessions are logged off. Use -Select to instead
        choose specific sessions interactively from a grid view (Out-GridView).

        Handles both RDP-named sessions (rdp-tcp#NN, via 'logoff' on the host) and
        numeric session IDs (via Invoke-RDUserLogoff).

        Supports -WhatIf / -Confirm. Use -WhatIf to preview which sessions would be
        logged off before committing -- recommended with the clear-all default.

    .PARAMETER ComputerName
        The remote computer whose sessions will be logged off. Mandatory (there is
        no local default) to avoid accidentally logging everyone off this machine.

    .PARAMETER Select
        Show a grid view of the sessions and log off only the ones you select,
        instead of logging off every session.

    .EXAMPLE
        Clear-LoggedOnSessions -ComputerName RDS01
        Logs off ALL sessions on RDS01.

    .EXAMPLE
        Clear-LoggedOnSessions -ComputerName RDS01 -WhatIf
        Shows which sessions would be logged off, without doing it.

    .EXAMPLE
        Clear-LoggedOnSessions -ComputerName RDS01 -Select
        Lists the sessions in a grid view; logs off only the ones you pick.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [Alias('RemoteComputerName')]
        [string]$ComputerName,

        [switch]$Select
    )

    # Get the list of logged-on sessions (skip the quser header row)
    $users = quser /server:$ComputerName 2>$null | Select-Object -Skip 1 | ForEach-Object {
        $parts = ($_.Trim() -replace '^>', '') -split '\s{2,}'
        [PSCustomObject]@{
            UserName    = $parts[0]
            SessionName = $parts[1]
            SessionID   = $parts[2]
            State       = $parts[3]
            IdleTime    = $parts[4]
            LogonTime   = $parts[5]
        }
    }

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
            if ($user.SessionID -match 'rdp-tcp#\d+') {
                # Handle RDP session names
                $sessionName = $user.SessionID
                Invoke-Command -ComputerName $ComputerName -ScriptBlock { logoff $using:sessionName }
            } else {
                # Handle numeric session IDs
                Invoke-RDUserLogoff -HostServer $ComputerName -UnifiedSessionID $user.SessionID -Force
            }
        }
    }
} #End Clear-LoggedOnSessions
