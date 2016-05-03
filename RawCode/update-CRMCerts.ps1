function Import-PfxCertificate {
   
<#
    .Link
        http://www.orcsweb.com/blog/james/powershell-ing-on-windows-server-how-to-import-certificates-using-powershell/
#>


    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String]$certPath,

        [String]$certRootStore = “CurrentUser”,

        [String]$certStore = “My”,

        [Parameter(Mandatory=$true, HelpMessage="Enter the pfx password”)]
        [String]$pfxPass = $null
    )
        
    $pfx = new-object System.Security.Cryptography.X509Certificates.X509Certificate2
 
    $pfx.import($certPath,$pfxPass,“Exportable,PersistKeySet”)
 
    $store = new-object System.Security.Cryptography.X509Certificates.X509Store($certStore,$certRootStore)
    $store.open(“MaxAllowed”)
    $store.add($pfx)
    $store.close()
}








# ----- update CRM cert 
# ----- http://blogs.msdn.com/b/crminthefield/archive/2012/01/18/instructions-for-updating-the-ssl-certificate-used-by-crm-2011-claims-based-and-or-ifd-environments.aspx

$VerbosePreference = "Continue"

# ----- get new cert
#$NewCertificate
$CertPath
$CertPass
$newcertthumb

# ----- Get old Cert
 $OldCertificate = invoke-command -ComputerName jeffb-crm03 -ScriptBlock {
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("My","LocalMachine")
    $store.Open("ReadOnly")
    write-output $Store.Certificates | where Thumbprint -eq 4DA5EA202424102D45EE51BFB6BFDCF1494680FE
}

$OldCertificate

# ----- Update the ADFS Server





$ComputerList = 'jeffb-crm03'

ForEach ( $C in $ComputerList ) {
    Write-Verbose "Checking certs on $C" 
    $Session = New-PSSession -ComputerName $C

    # ----- Check if old cert exists in the cert store and if so add new cert
    invoke-Command -Session $Session -argumentlist $OldCertificate -ScriptBlock {
        param ( 
            $OldCert,
            [String]$certpath,
            [String]$CertPass
        )
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("My","LocalMachine")
        $store.Open("ReadOnly")
        foreach ( $Cert in $Store.Certificates ) {
            if ( $Cert -eq $OldCert ) {
                # ----- Import new cert
                Import-PfxCertificate -certPath $CertPath -certRootStore LocalMachine -certStore My -pfxPass $CertPass
                "Oldcertexists"
                Break
            }
        }
    }
    
    # ----- Process CRM server
    if ( invoke-command -Session $Session -ScriptBlock { (Get-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* ).DisplayName -eq 'Microsoft Dynamics CRM Server 2011' } ) {
            Write-Verbose "Processing CRM Server"
            Invoke-Command -Session $Session -argumentlist $OldCertificate,$NewCertThumb -ScriptBlock { 
                param ( $OldCert,$NewThumb )
                $WebSites = Get-Website
                foreach ( $W in $Websites ) {
                    # ----- Get Website SSL Cert
                    $binding = Get-ChildItem IIS:SSLBindings
                    $Thumb =  $Binding | where { $SiteName -contains $_.Sites.Value } | Select-Object -ExpandProperty Thumbprint
                    $Cert = (Get-ChildItem CERT:LocalMachine/My | where { $Thumb -contains $_.Thumbprint })
                    if ( $Cert -eq $OldCert ) {
                        # ----- bind new cert to website
                        get-item -Path "cert:\localmachine\my\$NewThumb" | new-item "iis:\sslbindings\$($Binding.IPAddress)!$($Binding.Port)"
                    }
                }
                # ----- Remove old cert

                # ----- reconfigure CRM Claims ADFS cert
                Import-Module 'c:\program files\Microsoft CRM\tools\Microsoft.CRM.Powershell.dll'
                    $Claims = Get-CRMSetting -SettingType ClaimsSettings
                    $Claims.EncryptionCertificate = $NewCert
                    

                    Set-CRMSetting -Setting $Claims
    }


}