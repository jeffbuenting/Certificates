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