Function shrinkvhd {
    $totalDriveUsageBefore = 0
    $totalDriveUsageAfter = 0
    $virtualMachines = Get-VM
    $VHDs = $virtualMachines.HardDrives.Path
    $VHDs | ForEach-Object {$totalDriveUsageBefore += ((Measure-Object -InputObject (Get-Item $_).Length -Sum).Sum / 1GB)}
    foreach ($virtualMachine in $virtualMachines) {
        Write-Host "Shrinking $($virtualMachine.Name)" -ForegroundColor Yellow
        if ($virtualMachine.State -eq "Running") {
            $runningPrompt = Read-Host -Prompt "The VM is still running. Enter `"Y`" to turn off, or anything else to skip."
            if ($runningPrompt -eq "y") {
                Write-Host "Stopping $($virtualMachine.Name)..."
                Stop-VM -Name $virtualMachine.Name
            }
        }
        foreach ($VHD in $($virtualMachine.HardDrives.Path)) {
            $driveUsageBefore = 0
            $driveUsageAfter = 0
            $driveUsageBefore += ((Measure-Object -InputObject (Get-Item $VHD).Length -Sum).Sum / 1GB)
            Write-Host "    Shrinking $VHD" -ForegroundColor Yellow
            Mount-VHD -Path $VHD -NoDriveLetter -ReadOnly
            Optimize-VHD -Path $VHD -Mode Full
            Optimize-VHD -Path $VHD -Mode Full
            Optimize-VHD -Path $VHD -Mode Full
            Dismount-VHD -Path $VHD
            $driveUsageAfter += ((Measure-Object -InputObject (Get-Item $VHD).Length -Sum).Sum / 1GB)
            Write-Host "    Drive before: $driveUsageBefore GB`n    Drive after: $driveUsageAfter GB"
        }
        
    }
    $VHDs | ForEach-Object {$totalDriveUsageAfter += ((Measure-Object -InputObject (Get-Item $_).Length -Sum).Sum / 1GB)}
    Write-Host "Shrinking complete" -ForegroundColor Yellow
    Write-Host "Drive usage before was $totalDriveUsageBefore GB`nDrive after before was $totalDriveUsageAfter GB"
    Write-Host "Total saved: $($totalDriveUsageBefore - $totalDriveUsageAfter) GB"
}
