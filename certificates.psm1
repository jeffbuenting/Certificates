﻿#---------------------------------------------------------------------------------------

Function Get-Cert {

<# 
    .Synopsis
        Retrieves certificates from the certificate store

    .Description
        Using .NET retrieves the certicates in the selected certificate store.  Either locall or on a remote computer.



    .Links
        http://blogs.technet.com/b/heyscriptingguy/archive/2011/02/16/use-powershell-and-net-to-find-expired-certificates.aspx
#>

    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeLine=$True)]  
        [String[]]$ComputerName = '.',

        [Validateset('CurrentUser','LocalMachine')]
        [String]$CertRootStore = 'CurrentUser',

        [String]$CertStore = 'My'
    )

    Process {
        ForEach ( $C in $ComputerName ) {
            Write-Verbose "Get-Cert : Getting Certificates on $C\$CertStore"
            $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("\\$C\$CertStore",$CertRootStore)
            $store.Open("ReadOnly")
            Write-Output $store.Certificates
            $Store.Close()
        }
    }
}

#---------------------------------------------------------------------------------------

Function Import-Cert {

<#
    .Link
        http://www.orcsweb.com/blog/james/powershell-ing-on-windows-server-how-to-import-certificates-using-powershell/

#>

    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeLine=$True)]  
        [String[]]$ComputerName = '.',

        [String]$certPath,

        [Validateset('CurrentUser','LocalMachine')]
        [String]$certRootStore = “CurrentUser”,

        [String]$certStore = “My”,

        $Password = $null
    )

    Process {
        Foreach ( $C in $ComputerName ) {
            Write-Verbose "import new Certificates on $C\$CertRootStore"
            if ( $Password -eq $Null ) {
                    Write-Verbose "Importing a certificate that does not require a password"

                    $pfx = new-object System.Security.Cryptography.X509Certificates.X509Certificate2
                    $pfx.import($certPath) 
                    $store = new-object System.Security.Cryptography.X509Certificates.X509Store("\\$C\$certStore",$certRootStore)
                    $store.open(“MaxAllowed”)
                    $store.add($pfx)
                    $store.close()
                    Write-Output (get-cert -ComputerName $C -CertRootStore $certRootStore -CertStore $CertStore | where ThumbPrint -eq $PFX.ThumbPrint)
                }
                else {
                    Write-Verbose "Importing a certificate that requires a password."

                    $pfx = new-object System.Security.Cryptography.X509Certificates.X509Certificate2

                    Write-Verbose "Password = $Password"
 
                    #if ($pfxPass -eq $null ) {$pfxPass = read-host “Enter the certificate password” -assecurestring}
 
                    $pfx.import($certPath,$Password,“Exportable,PersistKeySet”)

                    if ( (get-cert -ComputerName $C -CertRootStore $certRootStore -CertStore $CertStore | where ThumbPrint -eq $PFX.ThumbPrint) -eq $Null ) {
                            Write-Verbose 'Certtificate does not exist, importing'
 
                            $store = new-object System.Security.Cryptography.X509Certificates.X509Store("\\$C\$certStore",$certRootStore)
                            $store.open(“MaxAllowed”)
                            $store.add($pfx)
                            $store.close()
                            Write-Output (get-cert -ComputerName $C -CertRootStore $certRootStore -CertStore $CertStore | where ThumbPrint -eq $PFX.ThumbPrint)
                        }
                        else {
                            Write-Verbose 'Certificate already exists.'
                            Write-Output (get-cert -ComputerName $C -CertRootStore $certRootStore -CertStore $CertStore | where ThumbPrint -eq $PFX.ThumbPrint)
                    }
            }

        }
    }
}

#---------------------------------------------------------------------------------------

Function Get-CertWebSite {

    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeLine=$True)]
        [String[]]$WebSiteName = "",  

        [Parameter(ValueFromPipeLine=$True)]
        [String[]]$ComputerName = '.'
    )

    Process {
        ForEach ( $C in $ComputerName ) {
            Write-Verbose "Getting website certs on computer $C"
             Write-Output ( Invoke-Command -ComputerName $C -argumentlist $WebSiteName -ScriptBlock { 
                Param ( [String]$WSN )

                import-module webadministration

                # ----- Run Verbose if calling function is verbose
                $VerbosePreference=$Using:VerbosePreference

                
                if ( $WSN -eq "" ) {
                        Write-Verbose "Get Certs for all HTTPS websites"
                        $WB = get-website | Select-Object -expandproperty Name  
                        foreach ( $W in $WB ) {
                            
                            $Thumb = Get-ChildItem IIS:SSLBindings | where { $W -contains $_.Sites.Value } | Select-Object -ExpandProperty Thumbprint
                            

                            $Cert = (Get-ChildItem CERT:LocalMachine/My | where { $Thumb -contains $_.Thumbprint })
                
                            $object = New-Object -TypeName psobject -Property (@{
                                'Name' = $W;
                                'Certificate' = $Cert
                            })
                
                            Write-Output $Object
                        }
                    }
                    else {
                        foreach ( $W in $WSN ) {
                            Write-Verbose "Get-CertWebsite : For website $W"
                            $Thumb = Get-ChildItem IIS:SSLBindings | where { $W -contains $_.Sites.Value } | Select-Object -ExpandProperty Thumbprint
                            Write-Verbose "Get-CertWebSite : Thumbnail = $($Thumb | Out-String)"
                            # ----- Check if THumb is empty and stop if it is
                            if ( -Not $Thumb ) {
                                Write-Verbose "Get-CertWebSite : Certificate is not bound to website"
                                Return
                            }

                            $Cert = (Get-ChildItem CERT:LocalMachine/My | where { $Thumb -contains $_.Thumbprint })
                            Write-Verbose "Get-CertWebSite : Certificate = $($Cert | Out-String)"

                            $object = New-Object -TypeName psobject -Property (@{
                                'Name' = $W;
                                'Certificate' = $Cert
                            })
                
                            Write-Output $Object
                        }
                }
            })
         }
    }
}

#---------------------------------------------------------------------------------------

Function Import-CertWebSite {

<#
    .Link
        http://www.iis.net/learn/manage/powershell/powershell-snap-in-configuring-ssl-with-the-iis-powershell-snap-in
#>


    [CmdletBinding()]
    param (
        
        [String[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory=$true)]
        [String]$WebSiteName,

        [Int]$Port = 443,

        [String]$IPAddress = '*',

        [String]$HostHeader = '',
        
        [Parameter(Mandatory=$true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate 
    )

    Process {
        Write-Verbose "Import-CertWebSite : Adding SSL Cert to Website $WebSiteName on "
  #      if ( $ComputerName = '.' ) {
  #              Write-Verbose "Import-CertWebSite :          Local Machine"
  #              import-module webadministration -force

  #              Write-Verbose "Import-CertWebSite : Binding to website"
  #              if ( ( Get-WebBinding -Name $WebSiteName -Protocol HTTPS -Port $Port -IPAddress $IPAddress -HostHeader $HostHeader ) -eq $Null ) {
  #
   #                     New-WebBinding -Name $WebSiteName -Protocol HTTPS -Port $Port -IPAddress $IPAddress -HostHeader $HostHeader

   #                     # ----- Assign cert to web binding
   #                     if ( $IPAddress -eq '*' ) { $IPAddress = '0.0.0.0' }
   #                     get-item "cert:\localMachine\my\$($Certificate.ThumbPrint)" | New-Item "IIS:\SSLBindings\$IPAddress!$Port"
   #                }
   #                 else {
   #                     Write-Verbose "Binding already exists for $WebSite HTTPS $($IPAddress):$($Port):$HostHeader"
   #             }
   #        }
   #         Else {
                Write-Verbose "Import-CertWebSite :          $ComputerName"
                Invoke-Command -ComputerName $ComputerName -Argumentlist $WebSiteName,$Port,$IPAddress,$HostHeader,$Certificate -ScriptBlock {
                        param (
                        [Parameter(Mandatory=$true)]
                        [String]$WebSiteName,

                        [Int]$Port = 443,

                        [String]$IPAddress = '*',

                        [String]$HostHeader = '',
        
                        [Parameter(Mandatory=$true)]
                        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate 
                    )

                    #----- Set verbose pref to what calling shell is set to
                    $VerbosePreference=$Using:VerbosePreference

                    import-module webadministration -force
                   
                    Write-Verbose "Import-CertWebSite : Binding to website"
                    New-WebBinding -Name $WebSiteName -Protocol HTTPS -Port $Port -IPAddress $IPAddress -HostHeader $HostHeader
            
                    Write-Verbose "Import-CertWebsite : Assign Cert to Web Binding"
                    # ----- Assign cert to web binding
                    if ( $IPAddress -eq '*' ) { $IPAddress = '0.0.0.0' }
                    New-Item "IIS:\SSLBindings\$IPAddress!$Port" -Value $Certificate
                }
  #      }
    }

}

#---------------------------------------------------------------------------------------

Function Remove-CertWebSite {

    [CmdletBinding()]
    param (
        
        [String[]]$ComputerName = '.',

        [Parameter(Mandatory=$true)]
        [String]$WebSiteName,

        [Int]$Port = 443,

        [String]$IPAddress = '*',

        [String]$HostHeader = '',
        
        [Parameter(Mandatory=$true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate 
    )

    Process {
        Write-Verbose "Removing SSL Binding from $WebSiteName"
        if ( $ComputerName = '.' ) {
                Write-Verbose "         Local Machine"
                import-module webadministration -force
                        
                # ----- Remove cert to web binding
                if ( $IPAddress -eq '*' ) { $IPAddress = '0.0.0.0' }
                get-item "cert:\localMachine\my\$($Certificate.ThumbPrint)" | Remove-Item "IIS:\SSLBindings\$IPAddress!$Port"
                        
                Get-WebBinding -Name $WebSiteName -Protocol HTTPS -Port $Port -IPAddress $IPAddress -HostHeader $HostHeader | Remove-WebBinding
            }
            Else {
                Write-Verbose "         $ComputerName"

                Invoke-Command -ComuterName $ComputerName -Argumentlist $WebSiteName,$Port,$IPAddress,$HostHeader,$Certificate -ScriptBlock {
                    param (
                        [Parameter(Mandatory=$true)]
                        [String]$WebSiteName,

                        [Int]$Port = 443,

                        [String]$IPAddress = '*',

                        [String]$HostHeader = '',
        
                        [Parameter(Mandatory=$true)]
                        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate 
                    )
                    
                    import-module webadministration -force
                        
                    # ----- Remove cert to web binding
                    if ( $IPAddress -eq '*' ) { $IPAddress = '0.0.0.0' }
                    get-item "cert:\localMachine\my\$($Certificate.ThumbPrint)" | Remove-Item "IIS:\SSLBindings\$IPAddress!$Port"
                        
                    Get-WebBinding -Name $WebSiteName -Protocol HTTPS -Port $Port -IPAddress $IPAddress -HostHeader $HostHeader | Remove-WebBinding
                }
        }
    }
}

#---------------------------------------------------------------------------------------

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

#---------------------------------------------------------------------------------------
        
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

    # ----- Even tho the full cert object is originally passed to the function.  Within the invoke-command I can't get the publick key.  So I only pass the thumbprint to the invoke-command block and then get the full cert object again.


    Invoke-Command -ComputerName $ComputerName -ArgumentList $Certificate.Thumbprint, $serviceAccount, $Permissions -ScriptBlock {
            param (
                [String]$ThumbPrint, 

                [string]$serviceAccount,

                [string]$Permissions
            )

        # ----- Run Verbose if calling function is verbose
            $VerbosePreference=$Using:VerbosePreference

        #$cert = Get-ChildItem -Path cert:\LocalMachine\My | Where-Object -FilterScript { $PSItem.ThumbPrint -eq $pfxThumbPrint; };
        Write-Verbose "Set-CertificatePermissions : Setting permissions on"

        $Cert = Get-Childitem Cert:\LocalMachine\my | where ThumbPrint -eq $ThumbPrint

        Write-Verbose "Set-CertPrivatekeyPermissions : Cert = $($Cert | Out-String)"

        # Specify the user, the permissions and the permission type
        $perm = "$($serviceAccount)",$Permissions,"Allow"

        $accessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $perm

        # Location of the machine related keys
        $keyPath = $env:ProgramData + "\Microsoft\Crypto\RSA\MachineKeys\";
        $keyName = $Cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName;
        $keyFullPath = $keyPath + $keyName;

        Write-Verbose "Set-CertPrivatekeyPermissions : Key Path = $KeyFullPath"
    
        try {
                # Get the current acl of the private key
                $acl = Get-Acl -Path $keyFullPath;

                # Add the new ace to the acl of the private key
                $acl.AddAccessRule($accessRule);

                # Write back the new acl
                Set-Acl -Path $keyFullPath -AclObject $acl;
            }
            catch {
                throw "Set-CertificatePermissions : $_"
        }
    }
}

Set-Alias -Name Import-CertWebSite -Value Bind-CertWebSite