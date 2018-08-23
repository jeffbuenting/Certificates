$ModulePath = Split-Path -Parent $MyInvocation.MyCommand.Path

$ModuleName = $ModulePath | Split-Path -Leaf

# ----- Remove and then import the module.  This is so any new changes are imported.
Get-Module -Name $ModuleName -All | Remove-Module -Force -Verbose

Import-Module "$ModulePath\$ModuleName.PSD1" -Force -ErrorAction Stop -Scope Global -Verbose

#-------------------------------------------------------------------------------------

Write-Output "`n`n"


Describe "Certificates : Get-Cert" {
   
    # ----- Get Function Help
    # ----- Pester to test Comment based help
    # ----- http://www.lazywinadmin.com/2016/05/using-pester-to-test-your-comment-based.html

    Context "Help" {
        $H = Help Get-Cert -Full
        
        # ----- Help Tests
        It "has Synopsis Help Section" {
            $H.Synopsis | Should Not BeNullorEmpty
        }

        It "has Description Help Section" {
            $H.Description | Should Not BeNullorEmpty
        }

        It "has Parameters Help Section" {
            $H.Parameters | Should Not BeNullorEmpty
        }

        # Examples
        it "Example - Count should be greater than 0"{
            $H.examples.example.code.count | Should BeGreaterthan 0
        }

        # Examples - Remarks (small description that comes with the example)
        foreach ($Example in $H.examples.example)
        {
            it "Example - Remarks on $($Example.Title)"{
                $Example.remarks | Should not BeNullOrEmpty
            }
        }

        It "has Notes Help Section" {
            $H.alertSet | Should Not BeNullorEmpty
        }
    } 

    Context Output {
        Mock -CommandName Invoke-Command -MockWith {
            & $ScriptBlock

           # $Obj = New-Object 'System.Security.Cryptography.X509Certificates.X509Certificate2'
           # Return $Obj
        }

        Mock -CommandName Get-ChildItem -MockWith {
            $Obj = New-Object 'System.Security.Cryptography.X509Certificates.X509Certificate2'
            Return $Obj
        }

        It "Outputs a certificate object" {
            Get-Cert #| Should beoftype 'System.Security.Cryptography.X509Certificates.X509Certificate2'
            Assert-MockCalled get-childitem -Scope it

        }
    }
}

#-------------------------------------------------------------------------------------

Write-Output "`n`n"


Describe "Certificates : Get-CertWebSite" {
   
    # ----- Get Function Help
    # ----- Pester to test Comment based help
    # ----- http://www.lazywinadmin.com/2016/05/using-pester-to-test-your-comment-based.html

    Context "Help" {
        $H = Help Get-CertWebSite -Full
        
        # ----- Help Tests
        It "has Synopsis Help Section" {
            $H.Synopsis | Should Not BeNullorEmpty
        }

        It "has Description Help Section" {
            $H.Description | Should Not BeNullorEmpty
        }

        It "has Parameters Help Section" {
            $H.Parameters | Should Not BeNullorEmpty
        }

        # Examples
        it "Example - Count should be greater than 0"{
            $H.examples.example.code.count | Should BeGreaterthan 0
        }

        # Examples - Remarks (small description that comes with the example)
        foreach ($Example in $H.examples.example)
        {
            it "Example - Remarks on $($Example.Title)"{
                $Example.remarks | Should not BeNullOrEmpty
            }
        }

        It "has Notes Help Section" {
            $H.alertSet | Should Not BeNullorEmpty
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