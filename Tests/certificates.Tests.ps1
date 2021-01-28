# ----- Get the module name
if ( -Not $PSScriptRoot ) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$ModulePath = $PSScriptRoot

$Global:ModuleName = $ModulePath | Split-Path -Leaf

# ----- Remove and then import the module.  This is so any new changes are imported.
Get-Module -Name $ModuleName -All | Remove-Module -Force -Verbose

Import-Module "$ModulePath\$ModuleName.PSD1" -Force -ErrorAction Stop  

#-------------------------------------------------------------------------------------
# ----- Check if all fucntions in the module have a unit tests

Describe "$ModuleName : Module Tests" {

    $Module = Get-module -Name $ModuleName -Verbose

    $testFile = Get-ChildItem $module.ModuleBase -Filter '*.Tests.ps1' -File -verbose
    
    $testNames = Select-String -Path $testFile.FullName -Pattern 'describe\s[^\$](.+)?\s+{' | ForEach-Object {
        [System.Management.Automation.PSParser]::Tokenize($_.Matches.Groups[1].Value, [ref]$null).Content
    }

    $moduleCommandNames = (Get-Command -Module $ModuleName | where CommandType -ne Alias)

    it 'should have a test for each function' {
        Compare-Object $moduleCommandNames $testNames | where { $_.SideIndicator -eq '<=' } | select inputobject | should beNullOrEmpty
    }
}

#-------------------------------------------------------------------------------------

Write-Output "`n`n"


Describe "$ModuleName  : Get-Cert" {
   
    # ----- Get Function Help
    # ----- Pester to test Comment based help
    # ----- http://www.lazywinadmin.com/2016/05/using-pester-to-test-your-comment-based.html

   Context "Help" {

            $H = Help Get-Cert -Full

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

    Context Output {
        Mock -CommandName Invoke-Command -MockWith {
            

            $Obj = New-Object 'System.Security.Cryptography.X509Certificates.X509Certificate2'
            Return $Obj
        }

        Mock -CommandName Get-ChildItem -MockWith {
            $Obj = New-Object 'System.Security.Cryptography.X509Certificates.X509Certificate2'
            Return $Obj
        }

        It "Outputs a certificate object" {
            Get-Cert | Should beoftype 'System.Security.Cryptography.X509Certificates.X509Certificate2'
            Assert-MockCalled get-childitem -Scope it

        } -Pending
    }
}

#-------------------------------------------------------------------------------------

Write-Output "`n`n"


Describe "$ModuleName  : Get-Cert" {
}

#-------------------------------------------------------------------------------------

Write-Output "`n`n"


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

#-------------------------------------------------------------------------------------

Write-Output "`n`n"


Describe "$ModuleName  : Import-CertWebSite" {
}

#-------------------------------------------------------------------------------------

Write-Output "`n`n"


Describe "$ModuleName  : Remove-CertWebSite" {
}

#-------------------------------------------------------------------------------------

Write-Output "`n`n"


Describe "$ModuleName  : Get-CertPrivateKeyPermissions" {
}

#-------------------------------------------------------------------------------------

Write-Output "`n`n"


Describe "$ModuleName  : Set-CertPrivateKeyPermissions" {
}