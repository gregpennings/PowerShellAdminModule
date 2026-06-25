function Get-LoggedOnSessions_OGV {
    <#
    .SYNOPSIS
        Shows the logged-on sessions of a computer in a grid view.

    .DESCRIPTION
        Runs quser against the target computer, parses the output into objects, and
        displays them in Out-GridView. Read-only -- it does not log anyone off (use
        Clear-LoggedOnSessions for that).

    .PARAMETER ComputerName
        The computer to query. Defaults to the local computer.

    .EXAMPLE
        Get-LoggedOnSessions_OGV -ComputerName RDS01

    .OUTPUTS
        None (displays a grid view).
    #>
    [CmdletBinding()]
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
    } | Out-GridView -Title "Logged-on sessions on $ComputerName"
}
