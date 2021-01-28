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
