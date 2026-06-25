function Test-Credential {
    <#
    .SYNOPSIS
        Validates a PSCredential against the domain, local machine, or an AD LDS instance.

    .DESCRIPTION
        Uses System.DirectoryServices.AccountManagement to validate the supplied
        credential. If the user name is in DOMAIN\user form, the domain part is used
        as the context target.

    .PARAMETER Credential
        The PSCredential to validate (e.g. from Get-Credential). Accepts pipeline input.

    .PARAMETER Context
        The validation context: Domain (default), Machine, or ApplicationDirectory.

    .EXAMPLE
        Get-Credential | Test-Credential
        Prompts for a credential and returns $true/$false for whether it validates.

    .EXAMPLE
        Test-Credential -Credential $cred -Context Machine

    .OUTPUTS
        System.Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Management.Automation.PSCredential]$Credential,

        [ValidateSet('Domain', 'Machine', 'ApplicationDirectory')]
        [string]$Context = 'Domain'
    )
    begin {
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
    }
    process {
        $parts = $Credential.UserName -split '\\'
        if ($parts.Length -eq 2) {
            $domain   = $parts[0]
            $userName = $parts[1]
        } else {
            $domain   = $null
            $userName = $Credential.UserName
        }

        $ctxType = [System.DirectoryServices.AccountManagement.ContextType]::$Context
        $principalContext = if ($domain) {
            [System.DirectoryServices.AccountManagement.PrincipalContext]::new($ctxType, $domain)
        } else {
            [System.DirectoryServices.AccountManagement.PrincipalContext]::new($ctxType)
        }

        $principalContext.ValidateCredentials($userName, $Credential.GetNetworkCredential().Password)
    }
}
