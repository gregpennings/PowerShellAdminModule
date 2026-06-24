function Get-CertificateCryptographicProvider_OGV {
    <#
    .SYNOPSIS
        Shows the key provider (CSP/KSP) information for a selected machine certificate.

    .DESCRIPTION
        Lists the certificates in Cert:\LocalMachine\My in a grid view; for the one
        you select, reads the CRYPT_KEY_PROV_INFO property via Crypt32/NCrypt P/Invoke
        and returns the provider/container details (useful for telling which
        cryptographic provider holds the private key).

    .EXAMPLE
        Get-CertificateCryptographicProvider_OGV

    .OUTPUTS
        PKI.Tools+CRYPT_KEY_PROV_INFO
    #>
    [CmdletBinding()]
    param()

$signature = @"
[DllImport("Crypt32.dll", SetLastError = true, CharSet = CharSet.Auto)]
public static extern bool CertGetCertificateContextProperty(
    IntPtr pCertContext,
    uint dwPropId,
    IntPtr pvData,
    ref uint pcbData
);
[StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
public struct CRYPT_KEY_PROV_INFO {
    [MarshalAs(UnmanagedType.LPWStr)]
    public string pwszContainerName;
    [MarshalAs(UnmanagedType.LPWStr)]
    public string pwszProvName;
    public uint dwProvType;
    public uint dwFlags;
    public uint cProvParam;
    public IntPtr rgProvParam;
    public uint dwKeySpec;
}
[DllImport("ncrypt.dll", SetLastError = true)]
public static extern int NCryptOpenStorageProvider(
    ref IntPtr phProvider,
    [MarshalAs(UnmanagedType.LPWStr)]
    string pszProviderName,
    uint dwFlags
);
[DllImport("ncrypt.dll", SetLastError = true)]
public static extern int NCryptOpenKey(
    IntPtr hProvider,
    ref IntPtr phKey,
    [MarshalAs(UnmanagedType.LPWStr)]
    string pszKeyName,
    uint dwLegacyKeySpec,
    uint dwFlags
);
[DllImport("ncrypt.dll", SetLastError = true)]
public static extern int NCryptGetProperty(
    IntPtr hObject,
    [MarshalAs(UnmanagedType.LPWStr)]
    string pszProperty,
    byte[] pbOutput,
    int cbOutput,
    ref int pcbResult,
    int dwFlags
);
[DllImport("ncrypt.dll", CharSet=CharSet.Auto, SetLastError=true)]
public static extern int NCryptFreeObject(
    IntPtr hObject
);
"@
Add-Type -MemberDefinition $signature -Namespace PKI -Name Tools

#
#

$CERT_KEY_PROV_INFO_PROP_ID = 0x2 # from Wincrypt.h header file
# $cert = (get-childitem -LiteralPath Cert:\LocalMachine\My\ | where {$psitem.issuer -like "*Let's*"})
$cert = Get-ChildItem -LiteralPath Cert:\LocalMachine\My\ | Out-GridView -PassThru
# initialize variables
$pcbData = 0
# get buffer size that will contain provider information
[void][PKI.Tools]::CertGetCertificateContextProperty($cert.Handle,$CERT_KEY_PROV_INFO_PROP_ID,[IntPtr]::Zero,[ref]$pcbData)
# allocate this buffer in unmanaged memory
$pvData = [Runtime.InteropServices.Marshal]::AllocHGlobal($pcbData)
# call the function again to copy provider information to a pointer.
[PKI.Tools]::CertGetCertificateContextProperty($cert.Handle,$CERT_KEY_PROV_INFO_PROP_ID,$pvData,[ref]$pcbData)
# copy structure from unmanaged memory to a managed structure
$keyProv = [Runtime.InteropServices.Marshal]::PtrToStructure($pvData,[type][PKI.Tools+CRYPT_KEY_PROV_INFO])
# we don't need unmanaged buffer, so release it
[Runtime.InteropServices.Marshal]::FreeHGlobal($pvData)
# display the key provider information
$keyProv
}
