Function AAResourceAccounts {
    param([Parameter(mandatory=$false)][String]$Name)
    $assignedAccounts = @()
    if ($Name) {
        $resourceAccountAAs = @()
        $resourceAccountAAs = @(Get-CsAutoAttendant | Where-Object {$_.Name -like "$Name"})
        if ($resourceAccountAAs) {
            foreach ($resourceAccountAA in $resourceAccountAAs) {
                Write-Host "Auto Attendant $($resourceAccountAA.Name) found" -ForegroundColor Cyan
                $resourceAccounts = $resourceAccountAA.ApplicationInstances
                if ($resourceAccounts) {
                    foreach ($resourceAccount in $resourceAccounts) {
                        $appInstance = Get-CsOnlineApplicationInstance -Identity $resourceAccount
                        $assignedAccounts += [PSCustomObject]@{
                            AutoAttendant = $resourceAccountAA.Name
                            DisplayName = $appInstance.DisplayName
                            UserPrincipalName = $appInstance.UserPrincipalName
                            LineUri = $appInstance.PhoneNumber
                        }
                    }
                } else {
                    Write-Host "Auto Attendant $($resourceAccountAA.Name) has no resource account assigned" -ForegroundColor Yellow
                }
            }
        } else {
            Write-Host "No Auto Attendants found with that name" -ForegroundColor Yellow
        }
    } else {
        $resourceAccountAAs = @()
        $resourceAccountAAs = @(Get-CsAutoAttendant)
        if ($resourceAccountAAs) {
            foreach ($resourceAccountAA in $resourceAccountAAs) {
                Write-Host "Auto Attendant $($resourceAccountAA.Name) found" -ForegroundColor Cyan
                $resourceAccounts = $resourceAccountAA.ApplicationInstances
                if ($resourceAccounts) {
                    foreach ($resourceAccount in $resourceAccounts) { 
                        $appInstance = Get-CsOnlineApplicationInstance -Identity $resourceAccount
                        $customProperties = @{
                            AutoAttendant = $resourceAccountAA.Name
                            DisplayName = $appInstance.DisplayName
                            UserPrincipalName = $appInstance.UserPrincipalName
                            LineUri = $appInstance.PhoneNumber
                        }
                        $assignedAccounts += New-Object -TypeName PSObject -Property $customProperties
                    }
                } else {
                    Write-Host "Auto Attendant $($resourceAccountAA.Name) has no resource account assigned" -ForegroundColor Yellow
                }
            }
        } else {
            Write-Host "No Auto Attendants found" -ForegroundColor Yellow
        }
    }
    $assignedAccounts
}
