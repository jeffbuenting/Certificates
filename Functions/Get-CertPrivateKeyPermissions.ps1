Function Get-CertPrivateKeyPermissions {
    
<#
    .Synopsis
        Retrieves the permissions on a Certificate's Private Key

    .Description
        Retrieves Permissions on a Certificate's Private Key.  Not the key itself but the security permissions.

    .Parameter ComputerName
        Name of the computer where the certificate is installed.

    .Parameter Certificate
        Certificate to get Private Key Permissions

    .Example
        Gets the certificate and then retrieves the private key permissions

        $SSLCert = Get-Cert -ComputerName $CRMServer -CertRootStore LocalMachine -CertStore My | where Subject -eq 'CN=*.Contoso.com, OU=Domain Control Validated'
            
        Get-CertPrivateKeyPermissions -ComputerName $CRMServer -Certificate $SSLCert -Verbose

    .Notes
        Author : Jeff Buenting
        Date : 2016 APR 26
    
#>

    [CmdletBinding()]
    param (
        [Parameter(Position=1)]
        [String]$ComputerName = $env:COMPUTERNAME,
        
        [Parameter(Position=2, Mandatory=$true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
    )

    Write-Verbose "Get-CertPrivateKeyPermissions : Getting Cert Privake key permissions"

    # ----- Even tho the full cert object is originally passed to the function.  Within the invoke-command I can't get the publick key.  So I only pass the thumbprint to the invoke-command block and then get the full cert object again.

    $Permissions = Invoke-Command -ComputerName $ComputerName  -argumentList $Certificate.Thumbprint -ScriptBlock {
        Param (
            [String]$ThumbPrint
        )
            # ----- Run Verbose if calling function is verbose
            $VerbosePreference=$Using:VerbosePreference

           # $Thumbprint ='63B900EBA08923FCB344E12F64919A2DB1FDDFF1'

            $Cert = Get-Childitem Cert:\LocalMachine\my | where ThumbPrint -eq $ThumbPrint
            #write-host "$($Cert | FL * | Out-string)"

    
            # Location of the machine related keys
            $keyPath = $env:ProgramData + "\Microsoft\Crypto\RSA\MachineKeys\";
            $keyName = $Cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName;
            $keyFullPath = $keyPath + $keyName;

            Write-Verbose "Get-CertPrivatekeyPermissions : Key Path = $KeyFullPath"

            # Get the current acl of the private key
            Write-Output (Get-Acl -Path $keyFullPath | select-object -ExpandProperty access )
    }

    Write-Output $Permissions

}