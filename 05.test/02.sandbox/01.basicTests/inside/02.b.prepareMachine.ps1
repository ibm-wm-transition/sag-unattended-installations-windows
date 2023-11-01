$l="c:/y/sandbox/pwshSandboxStartup.log"
Function LogWrite
{
  Param ([string]$logstring)
  Add-content $l -value "02.b - $logstring"
}

LogWrite "Starting..."

LogWrite "Importing module Pester v 5.5.0 ..."
Install-Module -Name Pester -RequiredVersion 5.5.0 -Force -SkipPublisherCheck

LogWrite "Finished..."

# Start-Process notepad "$l"
Start-Process "C:\Program Files\PowerShell\7\pwsh.exe" -ArgumentList "-noexit", "-command c:\s\03.runLocalTests.ps1"
