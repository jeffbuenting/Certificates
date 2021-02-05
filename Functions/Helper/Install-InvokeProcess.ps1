
# ----- Install Function that allows process to return error and output
# https://adamtheautomator.com/powershell-start-process/

Write-Verbose "Checking for Invoke-Process..."

if ( -Not ( Test-Path -Path 'C:\Program Files\WindowsPowerShell\Scripts\Invoke-Process.ps1' ) ) {
    Write-Verbose "Installing Invoke-Process"

    Install-Script 'Invoke-Process' -Scope AllUsers -Confirm:$false -Force
}
Write-Verbose "Dot Sourcing Invoke-Process"

Get-InstalledScript -Name Invoke-Process | fl *

. 'C:\Program Files\WindowsPowerShell\Scripts\Invoke-Process.ps1'
