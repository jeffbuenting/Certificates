#--------------------------------------------------------------------------------------
# Module for Certificates
#--------------------------------------------------------------------------------------

# ----- Install Function that allows process to return error and output
# https://adamtheautomator.com/powershell-start-process/
if ( -Not ( Test-Path -Path 'C:\Program Files\WindowsPowerShell\Scripts\Invoke-Process.ps1' ) ) {
    Install-Script 'Invoke-Process' -Scope AllUsers -Confirm:$false -Force
}
& 'C:\Program Files\WindowsPowerShell\Scripts\Invoke-Process.ps1'

# -------------------------------------------------------------------------------------
# ----- Dot source the functions in the Functions folder of this module
# ----- Ignore any file that begins with @, this is a place holder of work in progress.

Get-ChildItem -path $PSScriptRoot\Functions\*.ps1 | where Name -notlike '@*' | Foreach { 
    Write-Verbose "Dot Sourcing $_.FullName"

    . $_.FullName 
}

#Set-Alias -Name Bind-CertWebSite -Value Import-CertWebSite