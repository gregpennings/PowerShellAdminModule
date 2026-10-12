function Get-QuserOutput {
    <#
    .SYNOPSIS
        Runs quser on a computer and returns its raw output lines.

    .DESCRIPTION
        Shared quser runner for Get-LoggedOnSession and Clear-LoggedOnSession.
        Pipe the result to ConvertFrom-QuserOutput.

        quser runs on the target itself (via Invoke-OnComputer: in-process
        locally, WinRM to the FQDN remotely), never as 'quser /server:X'.
        /server: goes over Terminal Services RPC, which hosts commonly refuse
        ("Error [1707]: The network address is invalid").

        quser's own error text is reported via Write-Error instead of being
        discarded, so a failed query no longer looks like "no sessions".
        quser's "No User exists for *" (nobody logged on) is not an error;
        it just returns nothing.

    .PARAMETER ComputerName
        The computer to query.

    .OUTPUTS
        System.String (quser output lines, header first).
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )

    # Splits quser's stdout from its stderr so "failed" can be told from "empty".
    $runQuser = {
        $raw = quser 2>&1
        $exitCode = $LASTEXITCODE
        [PSCustomObject]@{
            Lines    = @($raw | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { "$_" })
            Errors   = @($raw | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | ForEach-Object { "$_".Trim() } | Where-Object { $_ })
            ExitCode = $exitCode
        }
    }

    try {
        $result = Invoke-OnComputer -ComputerName $ComputerName -ScriptBlock $runQuser
    } catch {
        Write-Error "Could not query sessions on ${ComputerName}: $($_.Exception.Message)"
        return
    }

    if ($result.Lines) {
        return $result.Lines
    }
    if ($result.Errors -match 'No User exists') {
        return
    }
    Write-Error "quser failed on ${ComputerName} (exit code $($result.ExitCode)): $($result.Errors -join ' ')"
}
