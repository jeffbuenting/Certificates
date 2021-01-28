
# ----- Get the module name
if ( -Not $PSScriptRoot ) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$ModulePath = $PSScriptRoot.substring(0,$PSScriptRoot.LastIndexOf('\'))

$Global:ModuleName = $ModulePath | Split-Path -Leaf

# ----- This line is required if the test is invoke by itself.  
if ( -Not (Get-Module -Name $ModuleName) ) { Import-Module "$ModulePath\$ModuleName.PSD1" -Force -ErrorAction Stop }


#-------------------------------------------------------------------------------------

Describe "$ModuleName  : New-CertCSR" {
    
  #  Mock -CommandName certreq -MockWith {
  #      New-item -ItemType File -Path TestDrive:\test.csr
  #  }

   
 #   Context INF {
 #       New-item -ItemType File -Path TestDrive:\request.inf
 #
 #       It "Should create CSR file" {
 #           New-CertCSR -INF TestDrive:\request.inf -CSRFile TestDrive:\test.csr
 #
 #           TestDrive:\test.csr | Should -Exist
 #       }
 #   }
 #
 #   Context FromParameters {
 #       
 #       It "Should create CSR file" {
 #           New-CertCSR -FQDN Server -CSRFile TestDrive:\test.csr
 #       
 #           #TestDrive:\test.csr | Should -Exist
 #       }
 #   }
}