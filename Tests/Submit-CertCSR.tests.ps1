
# ----- Get the module name
if ( -Not $PSScriptRoot ) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$ModulePath = $PSScriptRoot.substring(0,$PSScriptRoot.LastIndexOf('\'))

$Global:ModuleName = $ModulePath | Split-Path -Leaf

# ----- This line is required if the test is invoke by itself.  
if ( -Not (Get-Module -Name $ModuleName) ) { Import-Module "$ModulePath\$ModuleName.PSD1" -Force -ErrorAction Stop }


#-------------------------------------------------------------------------------------

Describe "$ModuleName  : Submit-CertCSR" {
    # ----- Not sure how to mock certreg   
 
}