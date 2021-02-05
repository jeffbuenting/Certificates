
# ----- Install Function that allows process to return error and output
# https://adamtheautomator.com/powershell-start-process/

Write-Verbose "Checking for Invoke-Process..."

if ( -Not ( Get-InstalledScript ) ) {
    Write-Verbose "Installing Invoke-Process"

    Install-Script 'Invoke-Process' -Scope AllUsers -Confirm:$false -Force
}
Write-Verbose "Dot Sourcing Invoke-Process"

. "$((Get-InstalledScript -Name Invoke-Process).InstalledLocation)\Invoke-Process.ps1"
