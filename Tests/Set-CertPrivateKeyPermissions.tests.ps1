# ----- Get the module name
if ( -Not $PSScriptRoot ) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

Write-Output "PSScriptRoot = $PSScriptRoot"

$ModulePath = $PSScriptRoot.substring(0,$PSScriptRoot.LastIndexOf('\'))

Write-output "ModulePath = $ModulePath"

$Global:ModuleName = $ModulePath | Split-Path -Leaf

Write-Output "ModuleName = $ModuleName"

# ----- This line is required if the test is invoke by itself.  
if ( -Not (Get-Module -Name $ModuleName) ) { Import-Module "$ModulePath\$ModuleName.PSD1" -Force -ErrorAction Stop }

#-------------------------------------------------------------------------------------

Describe "$ModuleName  : Set-CertPrivateKeyPermissions" {
}