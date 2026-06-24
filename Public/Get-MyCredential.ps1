function Get-MyCredential {
    <#
    .SYNOPSIS
        Loads a stored PSCredential from a file, creating it on first use.

    .DESCRIPTION
        Returns a PSCredential loaded from a CLIXML file at the given path. If the
        file does not exist, prompts for a credential (Get-Credential) and saves it
        there first via Export-Credential.

    .PARAMETER CredPath
        Path to the credential CLIXML file.

    .EXAMPLE
        $cred = Get-MyCredential -CredPath C:\creds\svc.xml

    .OUTPUTS
        System.Management.Automation.PSCredential

    .NOTES
        The stored password is DPAPI-protected: it can only be decrypted by the same
        Windows user on the same machine that created the file.
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', 'CredPath',
        Justification = 'CredPath is a file path to a CLIXML credential file, not a password.')]
    [OutputType([System.Management.Automation.PSCredential])]
    param(
        [Parameter(Mandatory)]
        [string]$CredPath
    )

    if (-not (Test-Path -Path $CredPath -PathType Leaf)) {
        Export-Credential -Credential (Get-Credential) -Path $CredPath
    }

    $stored = Import-Clixml -Path $CredPath
    $stored.Password = $stored.Password | ConvertTo-SecureString
    [System.Management.Automation.PSCredential]::new($stored.UserName, $stored.Password)
}
