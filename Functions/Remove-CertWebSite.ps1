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
