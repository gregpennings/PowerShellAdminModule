function Start-RDP {
    <#
    .SYNOPSIS
        Opens an RDP session to a computer using a supplied credential.

    .DESCRIPTION
        Stores the credential for the target with cmdkey, writes a temporary .rdp
        file (signed with the first Code Signing certificate in CurrentUser\My if one
        exists), launches mstsc against it, then schedules a background job to remove
        the stored credential and temp file after 30 seconds.

    .PARAMETER ComputerName
        The target computer / RDP host.

    .PARAMETER Cred
        The credential used for the session.

    .EXAMPLE
        Start-RDP -ComputerName SERVER01 -Cred (Get-Credential)

    .EXAMPLE
        $cred = Get-MyCredential -CredPath C:\creds\admin.xml
        Start-RDP SERVER01 -Cred $cred
        Start-RDP SERVER02 -Cred $cred
        Load an admin credential once (positional ComputerName) and reuse it across
        several RDP sessions.

    .OUTPUTS
        None.

    .NOTES
        SECURITY: the password is passed to cmdkey on the command line
        (/pass:<password>), so it is briefly visible to anyone who can enumerate
        process command lines on this machine. The stored credential is removed by a
        background job ~30 seconds later.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Cred
    )

    # Extract username and password
    $username = $Cred.UserName
    $password = $Cred.GetNetworkCredential().Password

    # Store credentials using cmdkey
    cmdkey /add:$ComputerName /user:$username /pass:$password

    # Create a temporary RDP file
    $rdpPath = [System.IO.Path]::GetTempFileName() + ".rdp"
    @"
screen mode id:i:1
desktopwidth:i:1920
desktopheight:i:1080
session bpp:i:32
full address:s:$ComputerName
username:s:$username
authentication level:i:2
prompt for credentials:i:0
"@ | Set-Content -Path $rdpPath -Encoding ASCII

    # Find the first available Code Signing certificate
    $cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object {
        $_.EnhancedKeyUsageList.FriendlyName -contains "Code Signing"
    } | Select-Object -First 1

    if (-not $cert) {
        Write-Warning "No code signing certificate found. Proceeding without signing."
    } else {
        # Sign the RDP file
        $thumbprint = $cert.Thumbprint -replace '\s',''
        & rdpsign.exe /sha256 $thumbprint $rdpPath
    }

    # Start RDP session
    Start-Process "mstsc.exe" -ArgumentList "`"$rdpPath`""

    # Run cleanup in the background
    Start-Job -ScriptBlock {
        param($target, $file)
        Start-Sleep -Seconds 30
        cmdkey /delete:$target
        Remove-Item -Path $file -Force
    } -ArgumentList $ComputerName, $rdpPath | Out-Null
}
