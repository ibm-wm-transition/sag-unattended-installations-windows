# Common powershell functions to be used for webMethods DevOps

## Assure constants
$defaultInstallerDownloadURL       = "https://empowersdc.softwareag.com/ccinstallers/SoftwareAGInstaller20230725-w64.exe"
$defaultInstallerFileHash          = "26236aac5e5c20c60d2f7862c606cdfdd86f08e0a1a39dbfc3e09d2ba50b8bce"
$defaultInstallerFileHashAlgorithm = "SHA256"

$defaultSumBootstrapDownloadURL        = "https://empowersdc.softwareag.com/ccinstallers/SoftwareAGUpdateManagerInstaller20230322-11-Windows.exe"
$defaultSumBootstrapFileHash           = "f64d438c23acd7d41f22e632ef067f47afc19f12935893ffc89ea2ccdfce1c02"
$defaultSumBootstraprFileHashAlgorithm = "SHA256"

# All executions are producing logs in the audit folder
$auditDir = $env:SUIF_AUDIT_DIR ?? "$env:TEMP/SUIF_AUDIT"
$logSessionDir = $env:SUIF_LOG_SESSION_DIR ?? "$auditDir/$(Get-Date (Get-Date).ToUniversalTime() -UFormat '+%Y-%m-%dT%H%M%S')"

New-Item -Path "$logSessionDir" -type Directory -Force | Out-Null

function Invoke-EnvironmentSubstitution() {
  param([Parameter(ValueFromPipeline)][string]$InputObject)

  Get-ChildItem Env: | Set-Variable
  $ExecutionContext.InvokeCommand.ExpandString($InputObject)
}


################################################### Log functions

function Debug-Log{
  param (
    # log message
    [Parameter(Mandatory=$true)]
    [string]$msg,
    # log severity
    [Parameter(Mandatory=$false)]
    [string]$sev=" INFO"
  )
  $fs = "$(Get-Date -Format "o") - $sev - $msg"
  Write-Host "$fs"
  Add-content "$logSessionDir/session.log" -value "$fs"
}

function Debug-SuifwLogI{
  param (
    # Where to download from
    [Parameter(Mandatory=$true)]
    [string]$msg
  )
  Debug-Log -msg $msg
}

function Debug-SuifwLogW{
  param (
    # Where to download from
    [Parameter(Mandatory=$true)]
    [string]$msg
  )
  Debug-Log -msg $msg -sev " WARN"
}

function Debug-SuifwLogE{
  param (
    # Where to download from
    [Parameter(Mandatory=$true)]
    [string]$msg
  )
  Debug-Log -msg $msg -sev "ERROR"
}

Debug-SuifwLogI "Module suifwCommon.psm1 Loaded"

################################################### Get Base Information Functions

function Get-InstallerDownloadURL(){
  return $env:installerDownloadURL ?? "$defaultInstallerDownloadURL"
}

function Get-InstallerFileHash(){
  return $env:installerFileHash ?? "$defaultInstallerFileHash"
}

function Get-InstallerFileHashAlgorithm(){
  return $env:installerFileHashAlgorithm ?? "$defaultInstallerFileHashAlgorithm"
}

function Get-SumBootstrapDownloadURL(){
  return $env:sumBootstrapDownloadURL ?? "$defaultSumBootstrapDownloadURL"
}

function Get-SumBootstrapFileHash(){
  return $env:sumBootstrapFileHash ?? "$defaultSumBootstrapFileHash"
}

function Get-SumBootstrapHashAlgorithm(){
  return $env:sumBootstrapFileHashAlgorithm ?? "$defaultSumBootstraprFileHashAlgorithm"
}

################################################### Internet Download Functions
function Get-WebFileWithChecksumVerification {
  param (
      # Where to download from
      [Parameter(Mandatory=$true)]
      [string]$url,

      # where to save the file 
      [Parameter(Mandatory=$false)]
      [string]$fullOutputDirectoryPath=$env:TEMP ?? "/tmp",

      # where to save the file 
      [Parameter(Mandatory=$false)]
      [string]$fileName="file.bin",
      # Hash to be checked
      [Parameter(Mandatory=$true)]
      [string]$expectedHash,

      # Hash to be checked
      [Parameter(Mandatory=$false)]
      [string]$hashAlgoritm="SHA256"
  )

  Debug-SuifwLogI "suifwCommon.psm1::Get-WebFileWithChecksumVerification() - Downloading file "$fullOutputDirectoryPath/$fileName""
  Debug-SuifwLogI "suifwCommon.psm1::Get-WebFileWithChecksumVerification() - From $url"
  Debug-SuifwLogI "suifwCommon.psm1::Get-WebFileWithChecksumVerification() - Guaranteeing $hashAlgoritm checksum $expectedHash"
  
  # assure destination folder
  Debug-SuifwLogI "Eventually create folder $fullOutputDirectoryPath..."
  New-Item -Path $fullOutputDirectoryPath -ItemType Directory -Force | Out-Null
  $fullFilePath = "$fullOutputDirectoryPath/$fileName"
  # Download the file
  Invoke-WebRequest -Uri $url -OutFile "$fullFilePath.verify"

  # Calculate the SHA256 hash of the downloaded file
  $fileHash = Get-FileHash -Path "$fullFilePath.verify" -Algorithm $hashAlgoritm
  Debug-SuifwLogI("suifwCommon.psm1::Get-WebFileWithChecksumVerification() - File hash is $fileHash.Hash .")
  Write-Host $fileHash
  # Compare the calculated hash with the expected hash
  $r = $false
  if ($fileHash.Hash -eq $expectedHash) {
    Rename-Item -Path "$fullFilePath.verify" -NewName "$fullFilePath"
    Debug-SuifwLogI "suifwCommon.psm1::Get-WebFileWithChecksumVerification() - The file's $hashAlgoritm hash matches the expected hash."
    $r = $true
  } else {
    Rename-Item -Path "$fullFilePath.verify" -NewName "$fullFilePath.dubious"
    Debug-SuifwLogE "suifwCommon.psm1::Get-WebFileWithChecksumVerification() - The file's $hashAlgoritm hash does not match the expected hash."
    Debug-SuifwLogE "suifwCommon.psm1::Get-WebFileWithChecksumVerification() - Got $fileHash.Hash, but expected $expectedHash!"
  }
  Debug-SuifwLogI("suifwCommon.psm1::Get-WebFileWithChecksumVerification returns $r")
  return $r
}

function Resolve-WebFileWithChecksumVerification{
  param (
    # Where to download from
    [Parameter(Mandatory=$true)]
    [string]$url,

    # where to save the file 
    [Parameter(Mandatory=$false)]
    [string]$fullOutputDirectoryPath=$env:TEMP ?? "/tmp",

    # where to save the file 
    [Parameter(Mandatory=$false)]
    [string]$fileName="/tmp/file.bin",
    # Hash to be checked
    [Parameter(Mandatory=$true)]
    [string]$expectedHash,

    # Hash to be checked
    [Parameter(Mandatory=$false)]
    [string]$hashAlgoritm="SHA256"
  )

  # Calculate the SHA256 hash of the downloaded file
  $fullFilePath = "$fullOutputDirectoryPath/$fileName"
  Debug-SuifwLogI("suifwCommon.psm1::Resolve-WebFileWithChecksumVerification() - checking file $fullFilePath ...")

  # if File exists, just check the checksum
  if (Test-Path $fullFilePath -PathType Leaf){
    Debug-SuifwLogI("suifwCommon.psm1::Resolve-WebFileWithChecksumVerification() - file $fullFilePath found.")
    $fileHash = Get-FileHash -Path $fullFilePath -Algorithm $hashAlgoritm
    Debug-SuifwLogI("suifwCommon.psm1::Resolve-WebFileWithChecksumVerification() - its hash is $fileHash.Hash .")
    if ($fileHash.Hash -eq $expectedHash) {
      Debug-SuifwLogI "suifwCommon.psm1::Resolve-WebFileWithChecksumVerification() - The file's $hashAlgoritm hash matches the expected hash."
      return $true
    } else {
        Debug-SuifwLogI("suifwCommon.psm1::Resolve-WebFileWithChecksumVerification() - checking file $fullFilePath ...")
      Debug-SuifwLogE "suifwCommon.psm1::Resolve-WebFileWithChecksumVerification() - The file's $hashAlgoritm hash does not match the expected hash. Downloaded file renamed"
      Debug-SuifwLogE "suifwCommon.psm1::Resolve-WebFileWithChecksumVerification() - Got $fileHash.Hash, but expected $expectedHash!"
      return $false
    }
  }
  Debug-SuifwLogI("suifwCommon.psm1::Resolve-WebFileWithChecksumVerification() - file $fullFilePath does not exist. Attempting to download...")
  $r = Get-WebFileWithChecksumVerification `
    -url "$url" `
    -fullOutputDirectoryPath "$fullOutputDirectoryPath" `
    -fileName "$fileName" `
    -expectedHash "$expectedHash" `
    -hashAlgoritm "$hashAlgoritm"
  
  Debug-SuifwLogI "suifwCommon.psm1::Resolve-WebFileWithChecksumVerification() - Initialize-SumBootstrapBinary returns $r"
  return $r
}

################################################### Initialize / Assure functions

function Initialize-InstallerBinary{
  param (
    # Where to download from
    [Parameter(Mandatory=$false)]
    [string]$url = $(Get-InstallerDownloadURL),

    # where to save the file 
    [Parameter(Mandatory=$false)]
    [string]$fullOutputDirectoryPath=$env:TEMP ?? "/tmp",

    # where to save the file 
    [Parameter(Mandatory=$false)]
    [string]$fileName="installer.exe",
    # Hash to be checked
    [Parameter(Mandatory=$false)]
    [string]$expectedHash = $(Get-InstallerFileHash),

    # Hash to be checked
    [Parameter(Mandatory=$false)]
    [string]$hashAlgoritm = $(Get-InstallerFileHashAlgorithm)
  )

  $r=Resolve-WebFileWithChecksumVerification `
    -url "$url" `
    -fullOutputDirectoryPath "$fullOutputDirectoryPath" `
    -fileName "$fileName" `
    -expectedHash "$expectedHash" `
    -hashAlgoritm "$hashAlgoritm"
  
  Debug-SuifwLogI "Initialize-InstallerBinary returns $r"
  return $r
}

function Initialize-SumBootstrapBinary{
  param (
    # Where to download from
    [Parameter(Mandatory=$false)]
    [string]$url = $(Get-SumBootstrapDownloadURL),

    # where to save the file 
    [Parameter(Mandatory=$false)]
    [string]$fullOutputDirectoryPath=$env:TEMP ?? "/tmp",

    # where to save the file 
    [Parameter(Mandatory=$false)]
    [string]$fileName="sum-bootstrap.exe",
    # Hash to be checked
    [Parameter(Mandatory=$false)]
    [string]$expectedHash = $(Get-SumBootstrapFileHash),

    # Hash to be checked
    [Parameter(Mandatory=$false)]
    [string]$hashAlgoritm = $(Get-SumBootstrapHashAlgorithm)
  )

  $r= Resolve-WebFileWithChecksumVerification `
      -url "$url" `
      -fullOutputDirectoryPath "$fullOutputDirectoryPath" `
      -fileName "$fileName" `
      -expectedHash "$expectedHash" `
      -hashAlgoritm "$hashAlgoritm"

  Debug-SuifwLogI "suifwCommon.psm1::Initialize-SumBootstrapBinary() - Return $r"
  return $r
}

################################################### Update Manger Bootstrap

function Install-UpdateManagerWithUnzip(){
  param (
    [Parameter(Mandatory=$false)]
    [string]$sumHome = "X:\SUM",
  
    [Parameter(Mandatory=$false)]
    [string]$sumBootstrapFolder = "$PSScriptRoot\..\03.artifacts",

    [Parameter(Mandatory=$false)]
    [string]$sumBootstrapFilename = "sum-bootstrap.exe"
  )

  # Check if we are admin
  $user = [Security.Principal.WindowsIdentity]::GetCurrent();
  if ( -Not (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)){
    Debug-SuifwLogE "suifwCommon.psm1::Install-UpdateManagerWithUnzip() - called without elevation. This cannot work in Windows!"
    throw "suifwCommon.psm1::Install-UpdateManagerWithUnzip() - called without elevation. This cannot work in Windows!"
  }
  Debug-SuifwLogI "suifwCommon.psm1::Install-UpdateManagerWithUnzip() - Boostrapping Update Manager from $sumBootstrap into folder $sumHome..."

  Debug-SuifwlogI "suifwCommon.psm1::Install-UpdateManagerWithUnzip() - Assuring the bootstrap binary file..."
  Initialize-SumBootstrapBinary -fullOutputDirectoryPath "$sumBootstrapFolder" -fileName "$sumBootstrapFilename"
  $sumBootstrap="$sumBootstrapFolder/$sumBootstrapFilename"
  #current timestamp in FS friendly form
  $ts=$(Get-Date (Get-Date).ToUniversalTime() -UFormat '+%Y-%m-%dT%H%M%S')
  $td="${env:TEMP}\sum-install-$ts".Replace("/","\")
  New-Item -ItemType Directory -Path "$td" -Force
  Expand-Archive -Force "$sumBootstrap" -DestinationPath "$td"

  Push-Location
  Set-Location "$td"

  $ld=$logSessionDir.Replace("/","\")
  $cmd = ".\sum-setup.bat --accept-license -d ""$sumHome"" >""$ld\sum-bootstrap.$ts.out.txt"" 2>""$ld\sum-bootstrap.$ts.err.txt"""
  Debug-SuifwLogI "suifwCommon.psm1::Install-UpdateManagerWithUnzip() - cmd == $cmd"

  cmd /c "$cmd"

  Pop-Location
  $ret=$?
  if ($ret -eq $True){
    Remove-Item "$td" -Force -Recurse
    Debug-SuifwLogI "suifwCommon.psm1::Install-UpdateManagerWithUnzip() - Update manager successfully installed."
  }else{
    Debug-SuifwLogE "suifwCommon.psm1::Install-UpdateManagerWithUnzip() - Update manager installation failed. Temporary folder $td maintained for investigation purposes!"
  }
  return $ret
}

function Install-UpdateManagerWithZFusionParams(){
  param (
    [Parameter(Mandatory=$false)]
    [string]$sumHome = "X:\SUM",
  
    [Parameter(Mandatory=$false)]
    [string]$sumBootstrapFolder = "$PSScriptRoot\..\03.artifacts",

    [Parameter(Mandatory=$false)]
    [string]$sumBootstrapFilename = "sum-bootstrap.exe"
  )

  # Check if we are admin
  $user = [Security.Principal.WindowsIdentity]::GetCurrent();
  if ( -Not (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)){
    Debug-SuifwLogE "suifwCommon.psm1::Install-UpdateManagerWithZFusionParams() - called without elevation. This cannot work in Windows!"
    throw "suifwCommon.psm1::New-SumBootstrap() - called without elevation. This cannot work in Windows!"
  }
  Debug-SuifwlogI "suifwCommon.psm1::Install-UpdateManagerWithZFusionParams() - Boostrapping Update Manager from $sumBootstrap into folder $sumHome..."

  Debug-SuifwlogI "suifwCommon.psm1::Install-UpdateManagerWithZFusionParams() - Assuring the bootstrap binary file..."
  Initialize-SumBootstrapBinary -fullOutputDirectoryPath "$sumBootstrapFolder" -fileName "$sumBootstrapFilename"

  $ts=$(Get-Date (Get-Date).ToUniversalTime() -UFormat '+%Y-%m-%dT%H%M%S')
  $td="${env:TEMP}\$ts"
  New-Item -ItemType Directory -Path "$td" -Force
  $f="${td}\sum-bootstrap.WMSCRIPT.$ts.txt"
  Debug-SuifwlogI "suifwCommon.psm1::Install-UpdateManagerWithZFusionParams() - Preparing the temporary script file $f ..."
  $fbat="${td}\sum-bootstrap.bat"

  "Repository=" > $f
  "imagePlatform=" >> $f
  "isAddFixes=true" >> $f
  "writeImageName=" >> $f
  "SumServer=" >> $f
  "readImageName=" >> $f
  $shr=$sumHome.Replace("\","\\").Replace(":","\:")
  "InstallDir=$shr" >> $f
  "useSSL=true" >> $f

  "SET ZFUSION_SUMINSTALL_ARGS=-readScript ""$f""" > $fbat
  $ld=$logSessionDir.Replace("/","\")
  $cmd="${sumBootstrapFolder}\${sumBootstrapFilename}".Replace("/","\")
  "${cmd} >>""$ld\sum-bootstrap.out.txt"" 2>>""$ld\sum-bootstrap.err.txt"""  >> $fbat
  Debug-SuifwlogI "suifwCommon.psm1::Install-UpdateManagerWithZFusionParams() - cmd == $fbat"
  cmd /c call "$fbat"
  $ret=$?

  if ($ret -eq $True){
    Remove-Item "$td" -Force -Recurse
    Debug-SuifwLogI "suifwCommon.psm1::Install-UpdateManagerWithZFusionParams() - Update manager successfully installed."
  }else{
    Debug-SuifwLogE "suifwCommon.psm1::Install-UpdateManagerWithZFusionParams() - Update manager installation failed. Temporary folder $td maintained for investigation purposes!"
  }
  return $ret
}

# Exports
Export-ModuleMember `
  -Function `
    Debug-SuifwLogE, `
    Debug-SuifwLogI, `
    Debug-SuifwLogW, `
    Get-InstallerDownloadURL,  `
    Get-InstallerFileHash,  `
    Get-InstallerFileHashAlgorithm,  `
    Get-SumBootstrapDownloadURL,  `
    Get-SumBootstrapFileHash,  `
    Get-SumBootstrapHashAlgorithm,  `
    Get-WebFileWithChecksumVerification, `
    Initialize-InstallerBinary, `
    Initialize-SumBootstrapBinary, `
    Install-UpdateManagerWithUnzip, `
    Install-UpdateManagerWithZFusionParams, `
    Invoke-EnvironmentSubstitution, `
    Resolve-WebFileWithChecksumVerification
