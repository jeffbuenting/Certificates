Function Submit-CertCSR {

<#
    .SYNOPSYS
        Submits CSR to certificate authority.
#>

    [CmdletBinding()]
    Param (
        [Parameter (Mandatory = $True)]
        [String]$CSRFile,

        [Parameter (Mandatory = $True)]
        [String]$IssueingCA,

        [Parameter (Mandatory = $True)]
        [String]$CertificateTemplate,

        [Parameter (Mandatory = $True)]
        [String]$CertFile
    )

    & certreq -submit -Config $IssueingCA -attrib $CertificateTemplate $CSRFile $CertFile | Write-Verbose
}