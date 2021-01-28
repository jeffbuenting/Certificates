Function New-CertCSR {

<#
    .SYNOPSIS
        Generates a Certificate Service Request (CSR).

    .DESCRIPTION
        Can be either from inf file or parameters (which will then create the INF file).

#>

    [CmdletBinding(DefaultParameterSetName = 'INF')]
    Param (
        [Parameter ( ParameterSetName = 'INF',Mandatory = $True  ) ]
        [String]$INF,

        [Parameter ( ParameterSetName = 'FromParameters',Mandatory = $True  )]
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
        [String[]]$SubjectAlternativeName,

        [Parameter ( ParameterSetName = 'INF',Mandatory = $True  ) ]
        [Parameter ( ParameterSetName = 'FromParameters',Mandatory = $True  )]
        [String]$CSRFile

    )

    if ( $PSCmdlet.ParameterSetName -eq 'FromParameters' ) {
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

    }

    if ( $PSCmdlet.ParameterSetName -eq 'INF' ) {
        Write-Verbose "Creating CSR from INF"
    }


    Write-Verbose "INF file = $INF"

    # ----- Create the request
    & certreq -new $INF $CSRFile
}