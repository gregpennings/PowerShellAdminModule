function Select-StringFromObject {
    <#
    .SYNOPSIS
        Greps the formatted text of pipeline objects -- Out-String -Stream | Select-String.

    .DESCRIPTION
        Renders the piped input the way it would display in the console (via
        Out-String -Stream) and runs Select-String over those lines, returning the
        matching lines. This packages the common idiom

            <command> | Out-String -Stream | Select-String <pattern>

        into a single grep-like step. The alias 'grep' is provided.

        All input is collected and formatted ONCE before matching, so table
        headers and column alignment are preserved (formatting per-object would
        repeat headers and misalign columns).

    .PARAMETER Pattern
        One or more regular-expression patterns to match (passed to Select-String).
        Use -SimpleMatch to treat them as literal text instead.

    .PARAMETER InputObject
        The objects to render and search. Accepts pipeline input.

    .PARAMETER CaseSensitive
        Match case-sensitively. By default matching is case-insensitive.

    .PARAMETER SimpleMatch
        Treat Pattern as literal text rather than a regular expression.

    .PARAMETER NotMatch
        Return the lines that do NOT match (Select-String -NotMatch).

    .PARAMETER Context
        Number of lines of context to capture around each match (Select-String -Context).

    .PARAMETER Width
        Line width used when rendering objects to text. Defaults to the host width;
        set a larger value (e.g. 4096) to stop wide tables being truncated before
        the match is searched.

    .EXAMPLE
        Get-ADUserGroupMembership jdoe | grep sql
        Lists jdoe's groups and keeps only the lines mentioning "sql".

    .EXAMPLE
        Get-Process | grep -Pattern 'chrome','msedge'
        Shows the process-table lines for either browser.

    .EXAMPLE
        Get-Service | grep -SimpleMatch -NotMatch Running
        Shows the service lines that are not running.

    .EXAMPLE
        Get-VMInfo | grep -Width 4096 10.1.2
        Widens the rendered table so a column isn't truncated before matching.

    .OUTPUTS
        Microsoft.PowerShell.Commands.MatchInfo (one per matching line).

    .NOTES
        Because it searches the FORMATTED text, matches depend on how the objects
        display (default table columns, truncation at the render width). For matching
        on actual property values, prefer Where-Object.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$Pattern,

        [Parameter(ValueFromPipeline)]
        [psobject]$InputObject,

        [switch]$CaseSensitive,

        [switch]$SimpleMatch,

        [switch]$NotMatch,

        [int]$Context = 0,

        [int]$Width
    )

    begin {
        $items = [System.Collections.Generic.List[object]]::new()
    }

    process {
        if ($null -ne $InputObject) { $items.Add($InputObject) }
    }

    end {
        $outStringParams = @{ Stream = $true }
        if ($PSBoundParameters.ContainsKey('Width')) { $outStringParams.Width = $Width }

        $selectStringParams = @{ Pattern = $Pattern }
        if ($CaseSensitive) { $selectStringParams.CaseSensitive = $true }
        if ($SimpleMatch)   { $selectStringParams.SimpleMatch   = $true }
        if ($NotMatch)      { $selectStringParams.NotMatch      = $true }
        if ($Context)       { $selectStringParams.Context       = $Context }

        $items | Out-String @outStringParams | Select-String @selectStringParams
    }
}

Set-Alias -Name grep -Value Select-StringFromObject
