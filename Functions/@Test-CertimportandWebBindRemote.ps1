


import-module F:\GitHub\Certificates\certificates.psm1 -Force

$File = Get-Item -Path $CertPFX
Copy-item -Path $CertPFX -Destination "\\$CRMServer\c$\temp\$($File.Name)" -Force

$Certificate = invoke-command -ComputerName $CRMServer -ArgumentList "c:\temp\$($File.Name)",$Password -ScriptBlock {
    param ( 
        [String]$CertPath,
        [System.Security.SecureString]$Password
    )

    if ( -Not ( Test-Path -Path $CertPath ) ) { Throw "Certificate path does not exist on remote computer" }

    $Cert = Import-pfxCertificate -FilePath $CertPath -CertStoreLocation cert:\localmachine\My -Password $Password 

    Write-Output $Cert
}


#$Certificate | FL *

Import-CertWebSite -ComputerName $CRMServer -WebSiteName "Microsoft Dynamics CRM" -Certificate $Certificate -verbose



