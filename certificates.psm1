#---------------------------------------------------------------------------------------

Function Get-Cert {

<# 
    .Synopsis
        Retrieves certificates from the certificate store

    .Description
        Gets a list of certificates from a coputer.

    .Parameter ComputerName
        Name of the computer to get certificates

    .Parameter CertRootStore
        Certificate root Store

    .Parameter CertRoot
        Certificate Root

    .Example
        Return all computer certificates for ServerA

        Get-Cert -ComputerName ServerA 

    .Notes
        Author : Jeff Buenting

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
            Write-Verbose "Getting Certs on $C"
            invoke-command -ComputerName $C -ArgumentList $CertRootStore,$CertStore -ScriptBlock {
                param (
                    [string]$CertRootStore,

                    [String]$CertStore
                )
                
                # ----- Run Verbose if calling function is verbose
                $VerbosePreference=$Using:VerbosePreference

                Write-Verbose "Get-Cert : Getting Certificates from $CertRootStore\$CertStore"

                Write-Output (Get-ChildItem -Path "Cert:\$CertRootStore\$CertStore" )

     #           $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($CertStore,$CertRootStore)
     #           $store.Open("ReadOnly")
     #           Write-Output $store.Certificates
     #           $Store.Close()
            }
        }
    }
}

#---------------------------------------------------------------------------------------



#---------------------------------------------------------------------------------------

Function Get-CertWebSite {

<#
    .Synopsis
        Finds Website Certificates

    .Description
        Finds Website Certificates

    .Parameter WebSiteName
        Name of the Website

    .Parameter ComputerName
        Computer name where the website resides.


#>

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
    .Synopsis
        Imports (binds) a certificate to a website.

    .Description
        Binding a certificate to a website is a two step process.  This cmdlet combines the two steps into one.  Creates the web binding and binds the Certificate to the website.

    .Parameter $ComputerName
        Name of the computer the website lives on.

    .parameter WebSiteName
        name of the website 

    .Parameter Port
        Port to bind to the website

    .Parameter IPAddress
        IP to bind to the website

    .Parameter HostHeader
        HostHeader to bind the website

    .Parameter Certificate
        Certificate to bind to the website

    .Example
        Import-CertWebSite -ComputerName $CRMServer -WebSiteName "Microsoft Dynamics CRM" -Certificate $Certificate -verbose

    .Link
        http://www.iis.net/learn/manage/powershell/powershell-snap-in-configuring-ssl-with-the-iis-powershell-snap-in

    .Note
        Author : Jeff Buenting
        Data : 2016 MAY 04
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
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,
        
        [PSCredential]$Credential 
    )

    Process {
        Write-Verbose "Import-CertWebSite : Adding SSL Cert to Website $WebSiteName on "
 
        Write-Verbose "Import-CertWebSite :          $ComputerName"
        Invoke-Command -ComputerName $ComputerName -Argumentlist $WebSiteName,$Port,$IPAddress,$HostHeader,$Certificate -Credential $Credential -ScriptBlock {
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

            Write-Verbose "-----------WebsiteName = $WebSiteName"

            #if ( -Not (Get-Module WebAdministration) ) { import-module webadministration }  
            
            get-website                

            Try {
                   if ( -Not ( Get-Webbinding -Name $WebSiteName -Protocol HTTPS -Port $Port -IPAddress $IPAddress -HostHeader $HostHeader -ErrorAction Stop ) ) {
                        Write-Verbose "Import-CertWebSite : Binding to website $WebSiteName"
                        New-WebBinding -Name $WebSiteName -Protocol HTTPS -Port $Port -IPAddress $IPAddress -HostHeader $HostHeader -ErrorAction Stop
                    }
                }
                Catch {
                    Throw "Import-CertWebsite : Error Binding to website.`n`n$($_.Exception.Message)"
            }
            
            
            Write-Verbose "Import-CertWebsite : Assign Cert to Web Binding"
            # ----- Assign cert to web binding
            if ( $IPAddress -eq '*' ) { $IPAddress = '0.0.0.0' }
            $IPAddress
            $Port
            "IIS:\SSLBindings\$IPAddress!$Port"

            if ( -Not ( Get-Item "IIS:\SSLBindings\$IPAddress!$Port" -ErrorAction SilentlyContinue ) ) {
                    # ----- Regetting the Cert as there is strangeness with the cert passed in.  
                    Get-Item "Cert:\LocalMachine\My\$($Certificate.Thumbprint)" | New-Item "IIS:\SSLBindings\$IPAddress!$Port"
            }
        }
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

#Set-Alias -Name Bind-CertWebSite -Value Import-CertWebSite