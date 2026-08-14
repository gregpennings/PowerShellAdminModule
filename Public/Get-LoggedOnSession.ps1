function Get-LoggedOnSession {
    <#
    .SYNOPSIS
        Returns the logged-on sessions of a computer as objects.

    .DESCRIPTION
        Runs quser against the target computer and parses the output into objects.
        Read-only -- it does not log anyone off (use Clear-LoggedOnSession for that).
        Pipe to Out-GridView (ogv), Where-Object, Format-Table, etc. as needed, or
        pipe straight to Clear-LoggedOnSession to log off just the sessions you've
        filtered to.

    .PARAMETER ComputerName
        The computer to query. Defaults to the local computer.

    .PARAMETER Select
        Show the sessions in a grid view (Out-GridView) and return only the
        ones you pick, instead of returning every session. Handy for piping
        straight into Clear-LoggedOnSession: the picker here replaces the
        one Clear-LoggedOnSession would otherwise show.

    .EXAMPLE
        Get-LoggedOnSession -ComputerName RDS01
        Returns every session on RDS01 as objects (no grid view).

    .EXAMPLE
        Get-LoggedOnSession -ComputerName RDS01 -Select
        Opens a grid view (Out-GridView) listing every session on RDS01; returns only
        the ones you pick and click OK.

    .EXAMPLE
        Get-LoggedOnSession -ComputerName RDS01 -Select | Clear-LoggedOnSession
        Pick sessions from the grid view here, then log off exactly those --
        Clear-LoggedOnSession logs off whatever it receives on the pipeline without
        showing its own picker, using each session's own ComputerName as the target.

    .EXAMPLE
        Get-LoggedOnSession -ComputerName RDS01 | Where-Object State -eq 'Disc' | Clear-LoggedOnSession
        Logs off only the disconnected sessions on RDS01.

    .OUTPUTS
        PSCustomObject (ComputerName, UserName, SessionName, SessionID, State,
        IdleTime, LogonTime).

    .LINK
    https://gregpennings.github.io/PowerShellAdminModule/Get-LoggedOnSession.html
#>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [string]$ComputerName = $env:COMPUTERNAME,

        [switch]$Select
    )

    if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
        Write-Warning "$ComputerName is not responding to ping."
        return
    }

    $sessions = quser /server:$ComputerName 2>$null | ConvertFrom-QuserOutput | ForEach-Object {
        [PSCustomObject]@{
            ComputerName = $ComputerName
            UserName     = $_.UserName
            SessionName  = $_.SessionName
            SessionID    = $_.SessionID
            State        = $_.State
            IdleTime     = $_.IdleTime
            LogonTime    = $_.LogonTime
        }
    }

    if ($Select) {
        $sessions | Out-GridView -Title "Select sessions on $ComputerName" -PassThru
    } else {
        $sessions
    }
}
