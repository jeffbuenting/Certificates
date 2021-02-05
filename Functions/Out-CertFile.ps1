Function Out-CertFile {

<#
    .SYNOPSIS
        Converts a cert from one format to another.

    .LINK
        https://michlstechblog.info/blog/powershell-export-convert-a-x509-certificate-in-pem-format/
#>

    [cmdletBinding()]
    Param (

        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Cert,

        [ ValidateSet ( 'PEM' ) ]
        [String]$Type,

        [String]$CertFile
    )

    Switch ( $Type ) {
        'PEM' {
            # 
            $InsertLineBreaks=1
            $ConvertedCert = new-object System.Text.StringBuilder
            $ConvertedCert.AppendLine("-----BEGIN CERTIFICATE-----")
            $ConvertedCert.AppendLine([System.Convert]::ToBase64String($Cert.RawData,$InsertLineBreaks))
            $ConvertedCert.AppendLine("-----END CERTIFICATE-----")
            $ConvertedCert.ToString() | out-file $CertFile
        }


    }

}