Function shrinkvhd {
param([Parameter(mandatory=$true)][String]$Path)
$Path = "D:\HyperV\VHD"
$runningVMs = Get-VM | ? {$_.State -eq "Running"}
Write-Host `n`n`n`n`n`n
if ($runningVMs) {
    Read-Host -Prompt "`nPress Enter to turn off, or Ctrl-C to cancel"
    Write-Host "The following VMs are still running:`n" -ForegroundColor Yellow
    Write-Output $runningVMs.Name}
foreach ($VM in $runningVMs) {
    Write-Host "Stopping $($VM.Name)..."
    Stop-VM -Name $VM.Name}
$VHDs = Get-ChildItem -Path $Path | Where-Object {$_.Extension -eq ".vhdx"}
$driveUsageBefore = (($VHDs | Measure-Object -Property length -Sum).Sum / 1GB)
foreach ($VHD in $VHDs) {
    Write-Host "Shrinking $($VHD.Name)" -ForegroundColor Yellow
    Mount-VHD -Path $VHD.FullName -NoDriveLetter -ReadOnly
    Optimize-VHD -Path $VHD.FullName -Mode Full
    Optimize-VHD -Path $VHD.FullName -Mode Full
    Optimize-VHD -Path $VHD.FullName -Mode Full
    Dismount-VHD -Path $VHD.FullName}
$driveUsageAfter = (((Get-ChildItem -Path $Path | Where-Object {$_.Extension -eq ".vhdx"}) | Measure-Object -Property length -Sum).Sum / 1GB)
Write-Host "Drive usage before was $driveUsageBefore GB`nDrive after before was $driveUsageAfter GB"
Write-Host "`nTotal saved: $($driveUsageBefore - $driveUsageAfter) GB"
}