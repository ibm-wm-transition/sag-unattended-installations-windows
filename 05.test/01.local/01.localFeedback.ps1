Import-Module "$PSScriptRoot/../../01.code/suifwCommon.psm1" -Force

### constants for this test
$expectedDefaultInstallerDownloadURL = "https://empowersdc.softwareag.com/ccinstallers/SoftwareAGInstaller20230725-w64.exe"
$expectedDefaultInstallerFileHash    = "26236aac5e5c20c60d2f7862c606cdfdd86f08e0a1a39dbfc3e09d2ba50b8bce"
$expectedDefaultInstallerFileHashAlg = "SHA256"

$expectedDefaultSumBootstrapDownloadURL  = "https://empowersdc.softwareag.com/ccinstallers/SoftwareAGUpdateManagerInstaller20230322-11-Windows.exe"
$expectedDefaultSumBootstrapFileHash     = "f64d438c23acd7d41f22e632ef067f47afc19f12935893ffc89ea2ccdfce1c02"
$expectedDefaultSumBootstraprFileHashAlg = "SHA256"

# Keep this up to date, use 5+
$pesterVersion='5.5.0'
function checkPester(){
  $pesterModules = @( Get-Module -Name "Pester" -ErrorAction "SilentlyContinue" );
  if( ($null -eq $pesterModules) -or ($pesterModules.Length -eq 0) )
  {
      throw "no pester module loaded!";
  }
  if( $pesterModules.Length -gt 1 )
  {
      throw "multiple pester modules loaded!";
  }
  if( $pesterModules[0].Version -ne ([version] "$pesterVersion") )
  {
      throw "unsupported pester version '$($pesterModules[0].Version)'";
  }
}
checkPester || exit 1 # Cannot continue if pester setup is incorrect 

Describe 'Checking Common Functions' {

  Context 'Safe File Downloads' {
    
    BeforeAll{
      # prepare a mock file
      $mf="$env:TEMP/mockfile.txt"
      Remove-Item $env:TEMP/file.bin* -Force | Out-Null
      Remove-Item "$env:TEMP/installer.exe*" -Force | Out-Null
      Remove-Item "${mf}*" -Force | Out-Null
      Add-Content $mf -value "Some Text here"

      $chksum = Get-FileHash -Path "$mf" -Algorithm SHA256

      Write-Host "Current hash for tests is $chksum.Hash"

      Mock -CommandName Invoke-WebRequest -ModuleName "suifwCommon" -MockWith {
        param(
          [Parameter(mandatory=$false)]
          [string] $uri='x',
          [Parameter(mandatory=$false)]
          [string] $OutFile="$env:TEMP/a.log"
        )
        Write-Host "Mocked Invoke-WebRequest, OutFile=$OutFile"
        Add-Content $OutFile -value "Some Text here"
      } # Mock Invoke-WebRequest to do nothing

      # Mock -CommandName Get-FileHash -ModuleName "suifwCommon" -MockWith{
      #   Write-Host "Mocked Get-FileHash, returning fized string 'EXPECTED_SHA256_HASH'"
      #   return @{Hash = 'EXPECTED_SHA256_HASH'}
      # } # Mock Get-FileHash to return a specific hash

      # Mock -CommandName Rename-Item -ModuleName "suifwCommon" -MockWith{
      #   Write-Host "Mocked Rename-Item - do nothing"
      # }
    }

    AfterAll{
      Remove-Item $env:TEMP/file.bin*
      Remove-Item "$mf"
    }
  
    It 'returns true when the hashes match' {
        $result = Get-WebFileWithChecksumVerification `
          -url 'http://example.com/file.txt' `
          -expectedHash $chksum.Hash
        $result | Should -Be $true
    }
  
    It 'returns false when the hashes do not match' {
        $result = Get-WebFileWithChecksumVerification `
        -url 'http://example.com/file.txt' `
        -expectedHash 'INCORRECT_SHA256_HASH'
        $result | Should -Be $false
    }
  
    It 'Initialize-InstallerBinary should return false'{
      $env:installerFileHashAlgorithm = $null
      $env:installerFileHash = $null
      $env:installerDownloadURL = $null
      Initialize-InstallerBinary | Should -Be $false
    }
  }
}

Describe 'Empower Defaults' {

  It 'Check Default Installer URL' {
    $env:installerDownloadURL = $null
    Get-InstallerDownloadURL | Should -Be $expectedDefaultInstallerDownloadURL
  }

  It 'Check Different Installer URL' {
    $env:installerDownloadURL = "a"
    Get-InstallerDownloadURL | Should -Be "a"
  }

  It 'Check Default Installer Hash' {
    $env:installerFileHash = $null
    Get-InstallerFileHash | Should -Be $expectedDefaultInstallerFileHash
  }

  It 'Check Different Installer Hash' {
    $env:installerFileHash = "a"
    Get-InstallerFileHash | Should -Be "a"
  }

  It 'Check Default Installer Hash Algorithm' {
    $env:installerFileHashAlgorithm = $null
    Get-InstallerFileHashAlgorithm | Should -Be $expectedDefaultInstallerFileHashAlg
  }

  It 'Check Different Installer Hash Algorithm' {
    $env:installerFileHashAlgorithm = "a"
    Get-InstallerFileHashAlgorithm | Should -Be "a"
  }


  It 'Check Default Sum Booststrap URL' {
    $env:sumBootstrapDownloadURL = $null
    Get-SumBootstrapDownloadURL | Should -Be $expectedDefaultSumBootstrapDownloadURL
  }

  It 'Check Different Sum Booststrap URL' {
    $env:sumBootstrapDownloadURL = "a"
    Get-SumBootstrapDownloadURL | Should -Be "a"
  }

  It 'Check Default Sum Booststrap Hash' {
    $env:sumBootstrapFileHash = $null
    Get-SumBootstrapFileHash | Should -Be $expectedDefaultSumBootstrapFileHash
  }

  It 'Check Different Sum Booststrap Hash' {
    $env:sumBootstrapFileHash = "a"
    Get-SumBootstrapFileHash | Should -Be "a"
  }

  It 'Check Default Sum Booststrap Hash Algorithm' {
    $env:sumBootstrapFileHashAlgorithm = $null
    Get-SumBootstrapHashAlgorithm | Should -Be $expectedDefaultSumBootstraprFileHashAlg
  }

  It 'Check Different Sum Booststrap Hash Algorithm' {
    $env:sumBootstrapFileHashAlgorithm = "a"
    Get-SumBootstrapHashAlgorithm | Should -Be "a"
  }

}

Describe 'Invoke-EnvironmentSubstitution'{
  It 'Substitutes env vars'{
    $inString = 'aa ${env:b} cc'
    $env:b = 'B'
    $inString | Invoke-EnvironmentSubstitution | Should -Be 'aa B cc'
  }
  It 'Substitutes absent vars'{
    $inString = 'aa ${env:b} cc'
    $env:b = $null
    $inString | Invoke-EnvironmentSubstitution | Should -Be 'aa  cc'
  }
}

Describe 'Resolves Without Mocks'{
  It 'Resolve Web File Checksum Fail'{
    $r = Get-Random -Maximum 999
    $d = "$env:TEMP/$r"
    New-Item -Path "$d" -ItemType Directory -Force
    $f = "$d/f.txt"
    
    Add-content "$f" -value "Some text"

    Resolve-WebFileWithChecksumVerification -url 'x' `
      -fullOutputDirectoryPath "$d" `
      -fileName "f.txt" `
      -expectedHash '1' | Should -be $false
    
    Remove-Item "$d" -Force -Recurse
  }
}
