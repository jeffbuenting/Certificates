function Set-CertPrivateKeyPermissions {
    
<#
    .Synopsis
        Sets private key permissions on certificates

    .Description
        Sets the Private Key Permissions on a certificate either locally or remotely.

    .Parameter ComputerName
        Name of the computer to set certificate permissions

    .Parameter Certificate
        Certificate to set permissions

    .Parameter ServiceAccount
        Name of the account to grant permissions

    .Parameter Permissions
        Permissions to Grant

    .Link
        http://stackoverflow.com/questions/20852807/

    .Note
        Author : Jeff Buenting
        Date : 2016 APR 25
#>

    [CmdletBinding()]
    param (
        [Parameter(Position=1)]
        [String]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Position=2, Mandatory=$true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate, 

        [Parameter(Position=3, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$serviceAccount,

        [Parameter(Position=4, Mandatory=$true)]
        [string]$Permissions
    )

  #  Enable-WSManCredSSP -Role "Client" -DelegateComputer $ComputerName
  #  Invoke-Command -ComputerName $ComputerName -ScriptBlock {
  #      Enable-WSMANCredSSP -Role Server -Force | Out-Null
  #  }

    # ----- Even tho the full cert object is originally passed to the function.  Within the invoke-command I can't get the publick key.  So I only pass the thumbprint to the invoke-command block and then get the full cert object again.
    Invoke-Command -ComputerName $ComputerName  -ArgumentList $Certificate.Thumbprint, $serviceAccount, $Permissions -ScriptBlock {
            param (
                [String]$ThumbPrint, 

                [Alias('ServiceAccount')]
                [String]$serviceAccountName,

                [string]$Permissions
            )
          
        # ----- Run Verbose if calling function is verbose
            $VerbosePreference=$Using:VerbosePreference

        #$cert = Get-ChildItem -Path cert:\LocalMachine\My | Where-Object -FilterScript { $PSItem.ThumbPrint -eq $pfxThumbPrint; };
        Write-Verbose "Set-CertificatePermissions : Setting permissions on"

        $Cert = Get-Childitem Cert:\LocalMachine\my | where ThumbPrint -eq $ThumbPrint

        Write-Verbose "Set-CertPrivatekeyPermissions : Cert = $($Cert | Out-String)"

        Write-Verbose "ServiceAccount = $ServiceAccountName"

        # Specify the user, the permissions and the permission type
        $perm = $serviceAccountName,$Permissions,"Allow"

        $accessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $perm
        Write-Verbose "AccessRule = $($AccessRule | FL * | Out-String )"

        # Location of the machine related keys
        $keyPath = $env:ProgramData + "\Microsoft\Crypto\RSA\MachineKeys\";
        $keyName = $Cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName;
        $keyFullPath = $keyPath + $keyName;

        Write-Verbose "Set-CertPrivatekeyPermissions : Key Path = $KeyFullPath"
    
        try {
                # Get the current acl of the private key
                $acl = Get-Acl -Path $keyFullPath
                Write-verbose "ACL = $($ACL | FL * | Out-String )"

                # Add the new ace to the acl of the private key
                $acl.AddAccessRule($accessRule)
                Write-Verbose "---------"
                Write-Verbose "New ACL = $($ACL | FL * | Out-String)"

                # Write back the new acl
                Set-Acl -Path $keyFullPath -AclObject $acl -Verbose
               
            }
            catch {
                throw "Set-CertificatePermissions : $_"
        }
    }

 #   Disable-WSManCredSSP -Role Client
 #   Invoke-Command -ComputerName $ComputerName -ScriptBlock {
 #        Disable-WSMANCredSSP -Role Server | Out-Null
 #  }
}