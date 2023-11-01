Import-Module -Name Pester -RequiredVersion 5.5.0
$env:SUIF_LOG_SESSION_DIR="c:/y/sandbox/session_logs"
P:\05.test\01.local\01.localFeedback.ps1

Write-Host "Feedback cycle 1 finished..."

P:\05.test\01.local\02.empowerDownloadSumFeedback.ps1

Write-Host "Feedback cycle 2 finished..."
