Function New-CertCSR {

<#
    .SYNOPSIS
        Generates a Certificate Service Request (CSR).

    .DESCRIPTION
        Can be either from inf file or parameters (which will then create the INF file).

    .LINK
        https://github.com/chrisdee/Scripts/blob/master/PowerShell/Working/certificates/GenerateCertificateSigningRequest(CSR).ps1
        https://dille.name/blog/2016/11/08/using-a-microsoft-ca-to-secure-docker/
        https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/certreq_1#syntax
        https://dille.name/blog/2011/12/23/how-to-request-a-certificate/

#>

    [CmdletBinding(DefaultParameterSetName = 'INF')]
    Param (
        [Parameter ( ParameterSetName = 'INF',Mandatory = $True  ) ]
        [String]$INF,

        [Parameter ( ParameterSetName = 'FromParameters',Mandatory = $True  )]
        [Parameter ( ParameterSetName = 'OpenSSL',Mandatory = $True )]
        [String]$FQDN,

        [Parameter ( ParameterSetName = 'FromParameters' )]
        [String]$Country,

        [Parameter ( ParameterSetName = 'FromParameters' )]
        [String]$Location,

        [Parameter ( ParameterSetName = 'FromParameters' )]
        [String]$State,

        [Parameter ( ParameterSetName = 'FromParameters' )]
        [String]$Organization,

        [Parameter ( ParameterSetName = 'FromParameters' )]
        [Parameter ( ParameterSetName = 'OpenSSL' )]
        [String[]]$SubjectAlternativeName,

        [Parameter ( ParameterSetName = 'INF',Mandatory = $True  ) ]
        [Parameter ( ParameterSetName = 'FromParameters',Mandatory = $True  )]
        [Parameter ( ParameterSetName = 'OpenSSL',Mandatory = $True )]
        [String]$CSRFile,

        [Parameter ( ParameterSetName = 'OpenSSL',Mandatory = $True )]
        [switch]$OpenSSL

    )

    switch ( $PSCmdlet.ParameterSetName ) {

        'FromParameters' {
            Write-Verbose "Creating CSR from Parameters"

            # ----- Build the subject 
            $Subject = "CN=$FQDN"
        
            if ( $Country ) {
                $Subject += ",C=$Country"
            }

            if ( $Location ) {
                $Subject += ",L=$Location"
            }

            if ( $State ) {
                $Subject += ",S=$State"
            }

            if ( $Organization ) {
                $Subject += ",O=$Organization"
            }

            # ----- SAN
            if ($SubjectAlternativeNames ) {
                $SAN = @()
                $SubjectAlternativeNames -split ',' | foreach {
                    $SAN += "_continue_ = ""DNS=$_&"""
                }
            }
            Else {
                $SAN = "_continue_ = ""DNS=$FQDN&"""
            }

            # ----- build CSR text
            $RequestINF = @"
[Version] 
Signature="`$Windows NT`$" 

[NewRequest] 
KeyLength =  2048
Exportable = TRUE 
MachineKeySet = TRUE 
SMIME = FALSE
RequestType =  PKCS10 
ProviderName = "Microsoft RSA SChannel Cryptographic Provider" 
ProviderType =  12
HashAlgorithm = sha256
Subject = "$Subject"

[Extensions]
2.5.29.17 = "{text}"
$SAN
"@
    
            Write-Verbose "`n$RequestINF"

            $INF = "$(($CSRFile | Split-Path -Parent))\$($FQDN)_CSR.inf"
    
            Set-Content -Value $RequestINF -Path $INF

            Write-Verbose "INF file = $INF"

            # ----- Create the request
            & certreq -new $INF $CSRFile | write-Verbose
        }

        'INF'{
            Write-Verbose "Creating CSR from INF"

            Write-Verbose "INF file = $INF"

            # ----- Create the request
            & certreq -new $INF $CSRFile | write-Verbose
        }

        'OpenSSL' {
            # ----- This section relys on third party openssl.exe 
            Write-Verbose "Creating CSR with OpenSSL"

            if ( Get-Command openssl.exe -ErrorAction SilentlyContinue ) {
                Write-Verbose "OpenSSL.exe is installed and in the windows path"
                $OSSLPath = ''
            }
            Elseif ( Test-Path -Path 'C:\Program Files\OpenSSL-Win64\bin\openssl.exe' ) {
                # ----- Try default path
                Write-Verbose "OpenSSL.exe is installed at C:\Program Files\OpenSSL-Win64\bin\"
                $OSSLPath = 'C:\Program Files\OpenSSL-Win64\bin\'
            }
            Else {
                Throw "New-CertCSR : openssl is either not installed or cannot be found"
            }

            # ----- Generate Config file for OpenSSL
            # https://www.switch.ch/pki/manage/request/csr-openssl/
            Write-Verbose "Generating CNF file (config file similar to info for certreq)"

            $SANCNF = @()
            $SANCNF += "[ alt_names ]"
            if ( $SubjectAlternativeName ) {
                $SANCNF += "subjectAltName = DNS:$FQDN, DNS:$($SubjectAlternativeNames -join ', DNS:')"
            }
            Else {
                $SANCNF += "subjectAltName = DNS:$FQDN"
            }

            #write-Verbose "CSRFile = $CSRFile"

            $SANCNF | Out-file "$($CSRFile | Split-Path -Parent)\SAN.cnf"

            # ----- OPENSSL does not outputs to the error stream and PS ISE does not like that so it thows an error.  Start-Process seems to fix tha tissue.
            # https://stackoverflow.com/questions/31449220/powershell-ise-wrongly-interprets-openssl-exe-normal-output-as-error#:~:text=Powershell%20interprets%20any%20dump%20into,Powershell%20as%20an%20actual%20error.

            # ----- Need to creat a key
            Write-Verbose "Private key..."
            Start-Process -filePath "$($OSSLPath)openssl.exe" -ArgumentList "genrsa -out $($CSRFile.Replace('csr','key')) 4096" -NoNewWindow

            # ----- Generate CSR
            Write-Verbose "CSR File..."
            Start-Process -FilePath "$($OSSLPath)openssl.exe" -ArgumentList "req -subj '/CN=$FQDN' -sha256 -new -key $($CSRFile.Replace('csr','key')) -out $CSRFile" -NoNewWindow
        }
    }
}