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
            Write-Verbose "import new Certificates on $C"

            invoke-command -ComputerName $C -ArgumentList $CertPath,$CertRootStore,$CertStore,$Password -ScriptBlock {
                param (
                    [String]$CertPath,

                    [string]$CertRootStore,

                    [String]$CertStore,

                    [String]$Password
                )
                
                # ----- Run Verbose if calling function is verbose
                $VerbosePreference=$Using:VerbosePreference
                
                if ( -Not ( Test-Path -Path $CertPath ) ) { Throw "Import-Cert : Certi"


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
 
                        try {
                                $OldErrorAction = $ErrorActionPreference
                                $ErrorActionPreference = 'Stop'
                                $pfx.import($certPath,$Password,“Exportable,PersistKeySet”) 
                            }
                            Catch {
                                $ErrorActionPreference = $OldErrorAction
                                Throw "Import-Cert : Error importing certificate on $C`n`n$($_.Exception.Message)"
                        }

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
}