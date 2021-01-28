#--------------------------------------------------------------------------------------
# Module for Certificates
#--------------------------------------------------------------------------------------

# -------------------------------------------------------------------------------------
# ----- Dot source the functions in the Functions folder of this module
# ----- Ignore any file that begins with @, this is a place holder of work in progress.


Get-ChildItem -path $PSScriptRoot\Functions\*.ps1 | where Name -notlike '@*' | Foreach { 
    Write-Verbose "Dot Sourcing $_.FullName"

    . $_.FullName 
}

#Set-Alias -Name Bind-CertWebSite -Value Import-CertWebSite