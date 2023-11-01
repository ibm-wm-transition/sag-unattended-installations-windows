
Import-Module "$PSScriptRoot/../../../01.code/suifwCommon.psm1" -Force

${env:currentDirectory}=$PSScriptRoot

${tempDir}="${env:TEMP}/suifw-01"

New-Item -ItemType Directory -Path "${tempDir}" -Force

Get-Content -Raw "$PSScriptRoot/suifw-01.wsb" | Invoke-EnvironmentSubstitution > "${tempDir}/suifw-01.wsb"

Start-Process -FilePath "C:\Windows\System32\WindowsSandbox.exe" `
  -ArgumentList "${tempDir}/suifw-01.wsb"
