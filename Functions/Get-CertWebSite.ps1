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

    .Example

    .Notes
        Author : Jeff Buenting


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