Function shrinkvhd {
    $driveUsageBefore = 0
    $driveUsageAfter = 0
    $virtualMachines = Get-VM
    $VHDs = $virtualMachines.HardDrives.Path
    $runningVMs = $virtualMachines| Where-Object {$_.State -eq "Running"}
    Write-Host `n`n`n`n`n`n
    if ($runningVMs) {
        Write-Host "The following VMs are still running:`n" -ForegroundColor Yellow
        Write-Output $runningVMs.Name
        Read-Host -Prompt "`nPress Enter to turn off, or Ctrl-C to cancel"
        foreach ($VM in $runningVMs) {
            Write-Host "Stopping $($VM.Name)..."
            Stop-VM -Name $VM.Name
        }
    }
    $VHDs | foreach {$driveUsageBefore += ((Measure-Object -InputObject (Get-Item $_).Length -Sum).Sum / 1GB)}
    foreach ($VHD in $VHDs) {
        Write-Host "Shrinking $VHD" -ForegroundColor Yellow
        Mount-VHD -Path $VHD -NoDriveLetter -ReadOnly
        Optimize-VHD -Path $VHD -Mode Full
        Optimize-VHD -Path $VHD -Mode Full
        Optimize-VHD -Path $VHD -Mode Full
        Dismount-VHD -Path $VHD
    }
    $VHDs | foreach {$driveUsageAfter += ((Measure-Object -InputObject (Get-Item $_).Length -Sum).Sum / 1GB)}
    Write-Host "Drive usage before was $driveUsageBefore GB`nDrive after before was $driveUsageAfter GB"
    Write-Host "`nTotal saved: $($driveUsageBefore - $driveUsageAfter) GB"
}
