Function Submit-CertCSR {

<#
    .SYNOPSYS
        Submits CSR to certificate authority.

    .LINK
        https://help.teradici.com/s/article/1147

        Convert Cert to PEM.  CER is the same as PEM (has BEGIN and END)

    .LINK
        https://knowledge.digicert.com/generalinformation/INFO2824.html
#>

    [CmdletBinding(DefaultParameterSetName = 'CER')]
    Param (
        [Parameter ( Mandatory = $True )]
        [String]$CSRFile,

        [Parameter ( Mandatory = $True )]
        [String]$IssueingCA,

        [Parameter ( Mandatory = $True )]
        [String]$CertificateTemplate,

        [Parameter ( Mandatory = $True )]
        [String]$CertFile
    )


    & certreq -submit -Config $IssueingCA -attrib $CertificateTemplate $CSRFile $CertFile | Write-Verbose

}