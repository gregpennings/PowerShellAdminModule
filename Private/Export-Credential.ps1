function Export-Credential {
    <#
    .SYNOPSIS
        (Private) Persists a PSCredential to an encrypted CLIXML file.

    .DESCRIPTION
        Stores the credential's password as a DPAPI-protected secure string inside a
        CLIXML file. The file can only be decrypted by the same Windows user on the
        same machine that created it. Used by Get-MyCredential.

    .PARAMETER Credential
        The credential to persist.

    .PARAMETER Path
        Destination file path for the CLIXML.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory)]
        [string]$Path
    )

    $copy = $Credential | Select-Object *
    $copy.Password = $copy.Password | ConvertFrom-SecureString
    $copy | Export-Clixml -Path $Path
}
