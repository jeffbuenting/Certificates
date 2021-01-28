# ----- Get the module name
if ( -Not $PSScriptRoot ) { $PSScriptRoot = $MyInvocation.MyCommand.Path }

$ModulePath = Split-Path $PSSCriptRoot -Parent

$Global:ModuleName = $ModulePath | Split-Path -Leaf

Write-Output "ModulePath = $ModulePath"


# ----- Remove and then import the module.  This is so any new changes are imported.
Get-Module -Name $ModuleName -All | Remove-Module -Force -Verbose

Write-Output "ModuleName = $ModuleName"

Import-Module "$ModulePath\$ModuleName.PSD1" -Force -ErrorAction Stop  

#-------------------------------------------------------------------------------------
# ----- Check if all fucntions in the module have a unit tests
    
Describe "$ModuleName : Module Tests" {

    $Module = Get-module -Name $ModuleName -Verbose

    $testFile = Get-ChildItem "$($Module.ModuleBase)\tests" -Filter '*.Tests.ps1' -File -verbose

    $testNames = Select-String -Path $testFile.FullName -Pattern 'describe\s[^\$](.+)?\s+{' | ForEach-Object {
        [System.Management.Automation.PSParser]::Tokenize($_.Matches.Groups[1].Value, [ref]$null).Content
    }

    $moduleCommandNames = (Get-Command -Module $ModuleName | where CommandType -ne Alias)

    it 'should have a test for each function' {
        Compare-Object $moduleCommandNames $testNames | where { $_.SideIndicator -eq '<=' } | select inputobject | should beNullOrEmpty
    }
}


#-------------------------------------------------------------------------------------

