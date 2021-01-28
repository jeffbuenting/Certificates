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

Describe "$ModuleName : Get-CertWebSite" {
   
    # ----- Get Function Help
    # ----- Pester to test Comment based help
    # ----- http://www.lazywinadmin.com/2016/05/using-pester-to-test-your-comment-based.html

    Context "Help" {
        $H = Help Get-CertWebSite -Full
        
        # ----- Help Tests
            It "has Synopsis Help Section" {
                 $H.Synopsis  | Should Not BeNullorEmpty
            }

            It "has Synopsis Help Section that it not start with the command name" {
                $H.Synopsis | Should Not Match $H.Name
            }

            It "has Description Help Section" {
                 $H.Description | Should Not BeNullorEmpty
            }

            It "has Parameters Help Section" {
                 $H.Parameters.parameter.description  | Should Not BeNullorEmpty
            }

            # Examples
            it "Example - Count should be greater than 0"{
                 $H.examples.example  | Measure-Object | Select-Object -ExpandProperty Count | Should BeGreaterthan 0
            }
            
            # Examples - Remarks (small description that comes with the example)
            foreach ($Example in $H.examples.example)
            {
                it "Example - Remarks on $($Example.Title)"{
                     $Example.remarks  | Should not BeNullOrEmpty
                }
            }

            It "has Notes Help Section" {
                 $H.alertSet  | Should Not BeNullorEmpty
            }
    } 

    Context Execution {
        It "Should return all website certificates if no website name is specified" {

        } -Pending

        It "Should return only the specified website certs" {

        } -Pending


    }

    Context Output {
        It "Should return custom object" {
            
        } -Pending

    }
}
