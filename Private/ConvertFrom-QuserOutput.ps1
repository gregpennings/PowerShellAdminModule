function ConvertFrom-QuserOutput {
    <#
    .SYNOPSIS
        Parses raw 'quser' output lines (including the header) into objects.

    .DESCRIPTION
        quser's columns are fixed-width, not whitespace-delimited. Splitting on
        runs of whitespace breaks as soon as a field is blank -- most commonly
        SESSIONNAME on a disconnected session with no session name -- because
        every column after it shifts left. That shift has landed STATE ("Disc")
        in the SessionID slot handed to Invoke-RDUserLogoff, which then fails
        converting "Disc" to Int32. Reading column offsets from the header row
        instead means a blank field just produces a blank value, not a shift.

    .PARAMETER Line
        A line of quser output, piped in as-is (including the header line --
        it's consumed to learn column positions, not emitted as an object).

    .OUTPUTS
        PSCustomObject (UserName, SessionName, SessionID, State, IdleTime, LogonTime).
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Line
    )

    begin {
        $columnNames = 'USERNAME', 'SESSIONNAME', 'ID', 'STATE', 'IDLE TIME', 'LOGON TIME'
        $starts = $null
    }

    process {
        if (-not $Line.Trim()) {
            return
        }

        if (-not $starts) {
            # First line is the header; learn each column's start position from it.
            $starts = @($columnNames | ForEach-Object { $Line.IndexOf($_) })
            return
        }

        # The '>' marker for the caller's own session sits in column 0 -- blank it
        # out instead of stripping it, so the fixed offsets below stay aligned.
        $padded = (' ' + $Line.Substring(1)).PadRight(200)

        $values = for ($i = 0; $i -lt $starts.Count; $i++) {
            $start = $starts[$i]
            $end = if ($i -lt $starts.Count - 1) { $starts[$i + 1] } else { $padded.Length }
            $padded.Substring($start, $end - $start).Trim()
        }

        [PSCustomObject]@{
            UserName    = $values[0]
            SessionName = $values[1]
            SessionID   = $values[2]
            State       = $values[3]
            IdleTime    = $values[4]
            LogonTime   = $values[5]
        }
    }
}
