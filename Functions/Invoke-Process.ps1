Function Invoke-Process {

<#
    .SYNOPSIS
        Similar to Start-Process but captures stdout and stderr
#>

    [CmdletBinding()]
    param (
        [Strin]$FilePath,

        [String]$ArgumentList
    )

    $Process = New-Object System.Diagnostics.ProcessStartInfo
    $Process.FileName = $FilePath
    $Process.RedirectStandardError = $true
    $Process.RedirectStandardOutput = $true
    $Process.UseShellExecute = $false
    $Process.Arguments = $ArgumentList
    $ProcessOut = New-Object System.Diagnostics.Process
    $ProcessOut.StartInfo = $pinfo
    $ProcessOut.Start() | Out-Null
    $ProcessOut.WaitForExit()

    Write-Output $ProcessOut
}