Function shrinkvhd {
    $totalDriveUsageBefore = 0
    $totalDriveUsageAfter = 0
    $virtualMachines = Get-VM
    $VHDs = $virtualMachines.HardDrives.Path
    $VHDs | ForEach-Object {$totalDriveUsageBefore += ((Measure-Object -InputObject (Get-Item $_).Length -Sum).Sum / 1GB)}
    $allVHDAbsolutePaths = @()
    foreach ($absoultePath in $virtualMachines.HardDrives.Path) {
        $allVHDAbsolutePaths += Get-Item $absoultePath | Select-Object DirectoryName
    }
    $allVHDDirectories = $allVHDAbsolutePaths | Select-Object -Unique
    $allUnattachedVHDs = @()
    foreach ($directoryName in $allVHDDirectories.DirectoryName) {
        $allUnattachedVHDs += Get-ChildItem -Path $directoryName -Recurse | Where-Object {$_.Extension -eq ".vhdx"} | Where-Object -FilterScript { $_.FullName -notin $VHDs } | Select-Object FullName
    }
    foreach ($virtualMachine in $virtualMachines) {
        Write-Host "Shrinking $($virtualMachine.Name)" -ForegroundColor Cyan
        if ($virtualMachine.HardDrives) {
            $virtualMachineVHDXs = $($virtualMachine.HardDrives.Path | Where-Object {$_ -like "*.vhdx"})
            $virtualMachineVHDs = $($virtualMachine.HardDrives.Path | Where-Object {$_ -like "*.vhd"})
            if ($virtualMachine.State -eq "Running") {
                $runningPrompt = Read-Host -Prompt "The VM is still running. Enter `"Y`" to turn off, or anything else to skip."
                if ($runningPrompt -eq "y") {
                    Write-Host "Stopping $($virtualMachine.Name)..."
                    Stop-VM -Name $virtualMachine.Name
                }
            }
            if ($virtualMachineVHDXs) {
                foreach ($virtualMachineDrive in $virtualMachineVHDXs) {
                    $driveUsageBefore = 0
                    $driveUsageAfter = 0
                    $driveUsageBefore += ((Measure-Object -InputObject (Get-Item $virtualMachineDrive).Length -Sum).Sum / 1GB)
                    Write-Host "    Shrinking $virtualMachineDrive" -ForegroundColor Yellow
                    Mount-VHD -Path $virtualMachineDrive -NoDriveLetter -ReadOnly
                    Optimize-VHD -Path $virtualMachineDrive -Mode Full
                    Optimize-VHD -Path $virtualMachineDrive -Mode Full
                    Optimize-VHD -Path $virtualMachineDrive -Mode Full
                    Dismount-VHD -Path $virtualMachineDrive
                    $driveUsageAfter += ((Measure-Object -InputObject (Get-Item $virtualMachineDrive).Length -Sum).Sum / 1GB)
                    Write-Host "    Before: $([math]::Round($driveUsageBefore,2)) GB`n    After:  $([math]::Round($driveUsageAfter,2)) GB"
                    Write-Host "    Shrunk: $([math]::Round(($driveUsageBefore - $driveUsageAfter),2)) GB"
                }
            } else {
                foreach ($virtualMachineDrive in $virtualMachineVHDs) {
                    Write-Host "    Non shrinkable drive $virtualMachineDrive" -ForegroundColor Red
                    $driveUsage = ((Measure-Object -InputObject (Get-Item $virtualMachineDrive).Length -Sum).Sum / 1GB)
                    Write-Host "    Size:   $([math]::Round($driveUsage,2)) GB"
                }
            }
        } else {
            Write-Host "    No drive attached to $($virtualMachine.Name)" -ForegroundColor Red
        }
    }
    if ($allUnattachedVHDs) {
        Write-Host "Found unattached VHDs:" -ForegroundColor Magenta
        foreach ($unattachedVHD in $allUnattachedVHDs) {
            Write-Host "$($unattachedVHD.FullName)"
        }
        foreach ($unattachedVHD in $allUnattachedVHDs) {
            $driveUsageBefore = 0
            $driveUsageAfter = 0
            $driveUsageBefore += ((Measure-Object -InputObject (Get-Item ($unattachedVHD.FullName)).Length -Sum).Sum / 1GB)
            Write-Host "    Shrinking $($unattachedVHD.FullName)" -ForegroundColor Yellow
            Mount-VHD -Path $($unattachedVHD.FullName) -NoDriveLetter -ReadOnly
            Optimize-VHD -Path $($unattachedVHD.FullName) -Mode Full
            Optimize-VHD -Path $($unattachedVHD.FullName) -Mode Full
            Optimize-VHD -Path $($unattachedVHD.FullName) -Mode Full
            Dismount-VHD -Path $($unattachedVHD.FullName)
            $driveUsageAfter += ((Measure-Object -InputObject (Get-Item $($unattachedVHD.FullName)).Length -Sum).Sum / 1GB)
            Write-Host "    Before: $([math]::Round($driveUsageBefore,2)) GB`n    After:  $([math]::Round($driveUsageAfter,2)) GB"
            Write-Host "    Shrunk: $([math]::Round(($driveUsageBefore - $driveUsageAfter),2)) GB"
        }
    }
    $VHDs | ForEach-Object {$totalDriveUsageAfter += ((Measure-Object -InputObject (Get-Item $_).Length -Sum).Sum / 1GB)}
    Write-Host "`nShrinking complete" -ForegroundColor Cyan
    Write-Host "Drive usage before was: $([math]::Round($totalDriveUsageBefore,2)) GB`nDrive usage after was:  $([math]::Round($totalDriveUsageAfter,2)) GB"
    Write-Host "Total saved:            $([math]::Round(($totalDriveUsageBefore - $totalDriveUsageAfter),2)) GB"
}
