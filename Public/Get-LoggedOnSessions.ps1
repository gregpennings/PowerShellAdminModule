function Get-LoggedOnSessions {
    <#
    .SYNOPSIS
        Returns the logged-on sessions of a computer as objects.

    .DESCRIPTION
        Runs quser against the target computer and parses the output into objects.
        Read-only -- it does not log anyone off (use Clear-LoggedOnSessions for that).
        Pipe to Out-GridView (ogv), Where-Object, Format-Table, etc. as needed.

    .PARAMETER ComputerName
        The computer to query. Defaults to the local computer.

    .EXAMPLE
        Get-LoggedOnSessions -ComputerName RDS01

    .EXAMPLE
        Get-LoggedOnSessions -ComputerName RDS01 | Out-GridView

    .OUTPUTS
        PSCustomObject (UserName, SessionName, SessionID, State, IdleTime, LogonTime).
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

    quser /server:$ComputerName 2>$null | Select-Object -Skip 1 | ForEach-Object {
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
}
