function Get-LoggedOnSessions {
    <#
    .SYNOPSIS
        Returns the logged-on sessions of a computer as objects.

    .DESCRIPTION
        Runs quser against the target computer and parses the output into objects.
        Read-only -- it does not log anyone off (use Clear-LoggedOnSessions for that).
        Pipe to Out-GridView (ogv), Where-Object, Format-Table, etc. as needed, or
        pipe straight to Clear-LoggedOnSessions to log off just the sessions you've
        filtered to.

    .PARAMETER ComputerName
        The computer to query. Defaults to the local computer.

    .EXAMPLE
        Get-LoggedOnSessions -ComputerName RDS01

    .EXAMPLE
        Get-LoggedOnSessions -ComputerName RDS01 | Out-GridView

    .EXAMPLE
        Get-LoggedOnSessions -ComputerName RDS01 | Where-Object State -eq 'Disc' | Clear-LoggedOnSessions
        Logs off only the disconnected sessions on RDS01.

    .OUTPUTS
        PSCustomObject (ComputerName, UserName, SessionName, SessionID, State,
        IdleTime, LogonTime).
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )

    if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
        Write-Warning "$ComputerName is not responding to ping."
        return
    }

    quser /server:$ComputerName 2>$null | ConvertFrom-QuserOutput | ForEach-Object {
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
}
