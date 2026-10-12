function Invoke-SessionLogoff {
    <#
    .SYNOPSIS
        Logs off a single quser session on a computer.

    .DESCRIPTION
        Shared logoff used by both of Clear-LoggedOnSession's parameter sets
        (-ComputerName loop and pipeline). Runs 'logoff <SessionID>' on the
        target itself via Invoke-OnComputer (in-process locally, WinRM to the
        FQDN remotely) -- the same transport Get-QuserOutput uses to list the
        sessions, so anything that can be listed can be logged off.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [Parameter(Mandatory = $true)]
        [string]$SessionID
    )

    # The caller already confirmed via its own ShouldProcess before calling this.
    # Suppress the ambient $ConfirmPreference so -Confirm on Clear-LoggedOnSession
    # doesn't bleed into ShouldProcess-aware cmdlets running underneath.
    $ConfirmPreference = 'None'

    # quser IDs are numeric; anything else means the row was misparsed, and
    # handing it to logoff could match the wrong session by name.
    if ($SessionID -notmatch '^\d+$') {
        Write-Error "Session ID '$SessionID' on $ComputerName is not numeric; not logging it off."
        return
    }

    $runLogoff = {
        param($Id)
        $out = logoff $Id 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "logoff $Id failed (exit code $LASTEXITCODE): $(($out | ForEach-Object { "$_".Trim() } | Where-Object { $_ }) -join ' ')"
        }
    }

    try {
        Invoke-OnComputer -ComputerName $ComputerName -ScriptBlock $runLogoff -ArgumentList $SessionID
    } catch {
        Write-Error "Could not log off session $SessionID on ${ComputerName}: $($_.Exception.Message)"
    }
}
