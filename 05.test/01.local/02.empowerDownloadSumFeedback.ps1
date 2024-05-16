Import-Module "$PSScriptRoot/../../01.code/suifwCommon.psm1" -Force

# This test assures the default update manager bootstrap then tries to bootstrap it accordinf to given automation functions

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

Describe 'Assure SumBootstrap'{
  It 'Full defaults'{
    $env:sumBootstrapFileHashAlgorithm = $null
    $env:sumBootstrapFileHash = $null
    $env:sumBootstrapDownloadURL = $null
    Initialize-SumBootstrapBinary -fullOutputDirectoryPath "K:" | Should -Be $true
  }
}

Describe 'Bootstrap SUM with defaults'{
  It 'Bootstrap SUM with Zipfusion parameters according to documentation'{
    Install-UpdateManagerWithZFusionParams -sumBootstrapFolder "K:" -sumBootstrapFilename "sum-bootstrap.exe"| Select-Object -Last 1 | Should -Be $true
  }
  It 'Bootstrap SUM with Unzip'{
    Install-UpdateManagerWithUnzip -sumBootstrapFolder "K:" -sumBootstrapFilename "sum-bootstrap.exe" -sumHome "X:\SUM2" | Select-Object -Last 1 | Should -Be $true
  }
}
