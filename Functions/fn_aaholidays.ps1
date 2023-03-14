Function AAHolidays {
    param([Parameter(mandatory=$false)][String]$Name)
    $holidaysObject = @()
    if ($Name) {
        $holidayAAs = @(Get-CsAutoAttendant | Where-Object {$_.Name -like "$Name"})
        if ($holidayAAs) {
            foreach ($holidayAA in $holidayAAs) {
                Write-Host "Auto Attendant $($holidayAA.Name) found" -ForegroundColor Cyan
                $holidays = Get-CsAutoAttendantHolidays -Identity $holidayAA.Identity -WarningAction SilentlyContinue
                if ($holidays) {
                    foreach ($holiday in $holidays) {
                        $startDate = Get-Date $holiday.DateTimeRanges.Start -Format dd-MMM-yyyy
                        $endDate = Get-Date $holiday.DateTimeRanges.End -Format dd-MMM-yyyy
                        $startTime = Get-Date $holiday.DateTimeRanges.Start -Format HH:mm
                        $endTime = Get-Date $holiday.DateTimeRanges.End -Format HH:mm
                        $customProperties = @{
                            AutoAttendant = $holidayAA.Name
                            Name = $holiday.Name
                            StartDate = $startDate
                            StartTime = $startTime
                            EndDate = $endDate
                            EndTime = $endTime
                        }
                        $holidaysObject += New-Object -TypeName PSObject -Property $customProperties
                    }
                } else {
                    Write-Host "`No holidays are configured for $($holidayAA.Name)"
                }
            }
        } else {
            Write-Host "No Auto Attendants found with that name" -ForegroundColor Yellow
        }
    } else {
        $holidayAAs = @(Get-CsAutoAttendant)
        if ($holidayAAs) {
            foreach ($holidayAA in $holidayAAs) {
                Write-Host "Auto Attendant $($holidayAA.Name) found" -ForegroundColor Cyan
                $holidays = Get-CsAutoAttendantHolidays -Identity $holidayAA.Identity -WarningAction SilentlyContinue
                if ($holidays) {
                    foreach ($holiday in $holidays) {
                        $startDate = Get-Date $holiday.DateTimeRanges.Start -Format dd-MMM-yyyy
                        $endDate = Get-Date $holiday.DateTimeRanges.End -Format dd-MMM-yyyy
                        $startTime = Get-Date $holiday.DateTimeRanges.Start -Format HH:mm
                        $endTime = Get-Date $holiday.DateTimeRanges.End -Format HH:mm
                        $customProperties = @{
                            AutoAttendant = $holidayAA.Name
                            Name = $holiday.Name
                            StartDate = $startDate
                            StartTime = $startTime
                            EndDate = $endDate
                            EndTime = $endTime
                        }
                        $holidaysObject += New-Object -TypeName PSObject -Property $customProperties
                    }
                } else {
                    Write-Host "No holidays are configured for $($holidayAA.Name)"
                }
            }
        } else {
            Write-Host "No Auto Attendants found" -ForegroundColor Yellow
        }
    }
    $holidaysObject | Select-Object AutoAttendant,Name,StartDate,StartTime,EndDate,EndTime | Format-Table -AutoSize
}
