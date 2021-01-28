Function Submit-CertCSR {

<#
    .SYNOPSYS
        Submits CSR to certificate authority.

    .LINK
        https://knowledge.digicert.com/generalinformation/INFO2824.html
#>

    [CmdletBinding(DefaultParameterSetName = 'CER')]
    Param (
        [Parameter (ParameterSetName = 'CER',Mandatory = $True)]
        [Parameter (ParameterSetName = 'PFX',Mandatory = $True)]
        [String]$CSRFile,

        [Parameter (ParameterSetName = 'CER',Mandatory = $True)]
        [Parameter (ParameterSetName = 'PFX',Mandatory = $True)]
        [String]$IssueingCA,

        [Parameter (ParameterSetName = 'CER',Mandatory = $True)]
        [Parameter (ParameterSetName = 'PFX',Mandatory = $True)]
        [String]$CertificateTemplate,

        [Parameter (ParameterSetName = 'CER',Mandatory = $True)]
        [Parameter (ParameterSetName = 'PFX',Mandatory = $True)]
        [ValidateScript ( {
            $ValidExtensions = 'CER','CRT','PFX'
            if ( ($Certfile -split '\.')[-1].toupper() -in $ValidExtensions ) {
                $True
            }
            Else {
                $False
            }
        })]
        [String]$CertFile
    )

    DynamicParam {
        if ( ($Certfile -split '\.')[-1].toupper() -eq "PFX") {
            
            # ----- PFXCredentials file requires PFXCredentials and password as it has the private key
            #create a new ParameterAttribute Object
            $PFXCredentialAttribute = New-Object System.Management.Automation.ParameterAttribute
            $PFXCredentialAttribute.ParameterSetName = 'PFX'
            $PFXCredentialAttribute.Mandatory = $true
 
            #create an attributecollection object for the attribute we just created.
            $attributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
 
            #add our custom attribute
            $attributeCollection.Add($PFXCredentialAttribute)
 
            #add our paramater specifying the attribute collection
            $PFXCredentialsParam = New-Object System.Management.Automation.RuntimeDefinedParameter('PFXCredential', [PSCredential], $attributeCollection)
 
            #expose the name of our parameter
            $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $paramDictionary.Add('PFXCredentials', $PFXCredentialParam)
            
            return $paramDictionary
        }
    }

    Process{
        if ( $PSCmdlet.ParameterSetName -eq 'CER' ) {
            & certreq -submit -Config $IssueingCA -attrib $CertificateTemplate $CSRFile $CertFile | Write-Verbose
        }

        if ( $PSCmdlet.ParameterSetName -eq 'PFX' ) {
            
            & certreq -submit -username $PFXCredential.Username -p $PFXCredential.GetNetwork().Credential -Config $IssueingCA -attrib $CertificateTemplate $CSRFile $CertFile | Write-Verbose
        }
    }
}