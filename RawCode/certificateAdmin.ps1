# ----- https://technet.microsoft.com/en-us/library/hh847807.aspx

Function Get-Cert {

<#
    .Synopsis
        Returns certificates
    
    .Description
        Returns either Computer or user certificates from either the local computer or a remote computer.

    .Parameter ComputerName
        Name of the computer from which to retrieve certificates.  LocalHost by default.

    .Parameter CertStoreRoot
        Specifies Computer (LocalMachine) or User (CurrentUser) certs to retrieve.

    .Parameter CertStore
        Specifies what certificate store to retireve.


#>

    [CmdletBinding()]
    param (
        [String]$ComputerName = '.',

        [ValidateSet('CurrentUser','LocalMachine')]
        [String]$CertStoreRoot = 'CurrentUser',

        [ValidateSet('AuthRoot','CA','ClientAuthIssuer','Disallowed','HomeGroup Machine Certificates','My','Remote Desktop','Root','SmartCardRoot','Trust','TrustedDevices','TrustedPeople','TrustedPublisher','Windows Live Id Token User')]
        [String]$CertStore = 'My'
    )

    Process {
        if ( $ComputerName -eq '.' ) {
                Write-Verbose "Get certificates from $CertStoreRoot\$CertStore on Local Computer"
                Write-Output (Get-ChildItem "Cert:\$CertStoreRoot\$CertStore")
            }
            Else {
                Write-Verbose "Get Certificates from Remote Computer"
                $RemoteCerts = Invoke-Command -ComputerName $ComputerName -ArgumentList "$CertStoreRoot\$CertStore" -ScriptBlock {
                    param ( $CertStorePath )

                    Write-Output (Get-ChildItem "Cert:\$CertStorePath" )
                }
                Write-Output $RemoteCerts
        }
    }

}

#--------------------------------------------------------------------------------------

Function Remove-Cert {

     [CmdletBinding()]
    param (
        [String]$ComputerName = '.',

        [Parameter(Mandatory=$true,ValueFromPipeline=$True)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Cert

    )

    Process {
        $CertStorePath = $Cert.PSParrentPath -replace  '::(.*)','$1'
        Write-Verbose "Deleting from $CertStorPath"

        if ( $ComputerName -eq '.' ) {
                Write-Verbose "Deleting Cert on local Machine"
                Remove-item -Path 'Cert:/$CertStorePath/$($Cert.ThumbPrint)'
            }
            else {
                Write-Verbose "Deleting cert on remote computer"
                Invoke-Command -ComputerName $ComputerName -ArgumentList "$CertStorePath/$($Cert.ThumbPrint)" -ScriptBlock {
                    param ( [String]$CertPath )
                    Remove-item -Path "Cert:/$CertPath"
                }
        }
    }
}


