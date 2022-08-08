Function AssignPS {
    [CmdletBinding()]Param(
        [string]$UserPrincipalName
    )
    # Get licenses SKUs for Phone System
    $msolAccountSkus = Get-MsolAccountSku
    $phoneSystemSku = $msolAccountSkus | ? {$_.AccountSkuId -like "*PHONESYSTEM_VIRTUALUSER*"}
    # Get number of available licenses
    $availablePhoneSystem = $phoneSystemSku.ActiveUnits - $phoneSystemSku.ConsumedUnits
    # Check the number of available Phone System licenses
    if ($availablePhoneSystem -gt 0) {  
        try {
            $msolUser = Get-MsolUser -UserPrincipalName $UserPrincipalName -ErrorAction Stop
            if ($msolUser.Licenses) {
                if ($msolUser.Licenses.AccountSkuId -like "*MCOEV*" -or $msolUser.Licenses.AccountSkuId -like "*MCOCAP*" -or $msolUser.Licenses.AccountSkuId -like "*PHONESYSTEM_VIRTUALUSER*") {
                    $assignedVoiceLicense = $msolUser.Licenses.AccountSkuId | ? {$_ -like "*MCOEV*" -or $_ -like "*MCOCAP*" -or $_ -like "*PHONESYSTEM_VIRTUALUSER*"}
                    Write-Host "$($msolUser.UserPrincipalName) is already licensed with $assignedVoiceLicense."
                } else {
                    Write-Warning "$($msolUser.UserPrincipalName) is not assigned any licenses."
                }
            } else {
                Write-Host "There are $availablePhoneSystem Phone System licenses available." -ForegroundColor Green
                Write-Host "Assigning $($phoneSystemSku.AccountSkuId) to $($msolUser.DisplayName)"
                if ( -not ($msolUser.UsageLocation)) {
                    Write-Warning "Usage Location is not set."
                    $usageLocation = Read-Host -Prompt "Enter the Usage Location to assign, for example `'US`'"
                    Set-MsolUser -ObjectId $msolUser.ObjectId -UsageLocation $usageLocation
                }
                try {
                    Set-MsolUserLicense -ObjectId $msolUser.ObjectId -AddLicenses $phoneSystemSku.AccountSkuId -ErrorAction Stop
                } catch {
                    Write-Warning "License assignment failed for $($msolUser.UserPrincipalName)"
                    Write-Host $_.Exception.Message -ForegroundColor Red
                }
            }
        } catch {
            Write-Warning "$UserPrincipalName was not found"
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    } else {
        Write-Warning "Not enough available Phone System licenses."
    }
}
Function AssignCAP {
    [CmdletBinding()]Param(
        [string]$UserPrincipalName
    )
    # Get licenses SKUs for Common Area Phone
    $msolAccountSkus = Get-MsolAccountSku
    $commonAreaSku = $msolAccountSkus | ? {$_.AccountSkuId -like "*PHONESYSTEM_VIRTUALUSER*"}
    # Get number of available licenses
    $availableCommonArea = $commonAreaSku.ActiveUnits - $commonAreaSku.ConsumedUnits
    # Check the number of available Common Area Phone licenses
    if ($availableCommonArea -gt 0) {  
        try {
            $msolUser = Get-MsolUser -UserPrincipalName $UserPrincipalName -ErrorAction Stop
            if ($msolUser.Licenses) {
                if ($msolUser.Licenses.AccountSkuId -like "*MCOEV*" -or $msolUser.Licenses.AccountSkuId -like "*MCOCAP*" -or $msolUser.Licenses.AccountSkuId -like "*PHONESYSTEM_VIRTUALUSER*") {
                    $assignedVoiceLicense = $msolUser.Licenses.AccountSkuId | ? {$_ -like "*MCOEV*" -or $_ -like "*MCOCAP*" -or $_ -like "*PHONESYSTEM_VIRTUALUSER*"}
                    Write-Host "$($msolUser.UserPrincipalName) is already licensed with $assignedVoiceLicense."
                } else {
                    Write-Warning "$($msolUser.UserPrincipalName) is not assigned any licenses."
                }
            } else {
                Write-Host "There are $availableCommonArea Common Area Phone licenses available." -ForegroundColor Green
                Write-Host "Assigning $($commonAreaSku.AccountSkuId) to $($msolUser.DisplayName)"
                if ( -not ($msolUser.UsageLocation)) {
                    Write-Warning "Usage Location is not set."
                    $usageLocation = Read-Host -Prompt "Enter the Usage Location to assign, for example `'US`'"
                    Set-MsolUser -ObjectId $msolUser.ObjectId -UsageLocation $usageLocation
                }
                try {
                    Set-MsolUserLicense -ObjectId $msolUser.ObjectId -AddLicenses $commonAreaSku.AccountSkuId -ErrorAction Stop
                } catch {
                    Write-Warning "License assignment failed for $($msolUser.UserPrincipalName)"
                    Write-Host $_.Exception.Message -ForegroundColor Red
                }
            }
        } catch {
            Write-Warning "$UserPrincipalName was not found"
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    } else {
        Write-Warning "Not enough available Common Area Phone licenses."
    }
}
Function AssignVU {
    [CmdletBinding()]Param(
        [string]$UserPrincipalName
    )
    # Get licenses SKUs for Virtual User
    $msolAccountSkus = Get-MsolAccountSku
    $virtualUserSku = $msolAccountSkus | ? {$_.AccountSkuId -like "*PHONESYSTEM_VIRTUALUSER*"}
    # Get number of available licenses
    $availableVirtualUser = $virtualUserSku.ActiveUnits - $virtualUserSku.ConsumedUnits
    # Check the number of available Virtual User licenses
    if ($availableVirtualUser -gt 0) {  
        try {
            $msolUser = Get-MsolUser -UserPrincipalName $UserPrincipalName -ErrorAction Stop
            if ($msolUser.Licenses) {
                if ($msolUser.Licenses.AccountSkuId -like "*MCOEV*" -or $msolUser.Licenses.AccountSkuId -like "*MCOCAP*" -or $msolUser.Licenses.AccountSkuId -like "*PHONESYSTEM_VIRTUALUSER*") {
                    $assignedVoiceLicense = $msolUser.Licenses.AccountSkuId | ? {$_ -like "*MCOEV*" -or $_ -like "*MCOCAP*" -or $_ -like "*PHONESYSTEM_VIRTUALUSER*"}
                    Write-Host "$($msolUser.UserPrincipalName) is already licensed with $assignedVoiceLicense."
                } else {
                    Write-Warning "$($msolUser.UserPrincipalName) is not assigned any licenses."
                }
            } else {
                Write-Host "There are $availableVirtualUser Virtual User licenses available." -ForegroundColor Green
                Write-Host "Assigning $($virtualUserSku.AccountSkuId) to $($msolUser.DisplayName)"
                if ( -not ($msolUser.UsageLocation)) {
                    Write-Warning "Usage Location is not set."
                    $usageLocation = Read-Host -Prompt "Enter the Usage Location to assign, for example `'US`'"
                    Set-MsolUser -ObjectId $msolUser.ObjectId -UsageLocation $usageLocation
                }
                try {
                    Set-MsolUserLicense -ObjectId $msolUser.ObjectId -AddLicenses $virtualUserSku.AccountSkuId -ErrorAction Stop
                } catch {
                    Write-Warning "License assignment failed for $($msolUser.UserPrincipalName)"
                    Write-Host $_.Exception.Message -ForegroundColor Red
                }
            }
        } catch {
            Write-Warning "$UserPrincipalName was not found"
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    } else {
        Write-Warning "Not enough available Virtual User licenses."
    }
}
Function AssignAC {
    [CmdletBinding()]Param(
        [string]$UserPrincipalName
    )
    # Get licenses SKUs for Audio Conferencing
    $msolAccountSkus = Get-MsolAccountSku
    $audioConfSku = $msolAccountSkus | ? {$_.AccountSkuId -like "*MCOMEETADV*"}
    # Get number of available licenses
    $availableAudioConf = $audioConfSku.ActiveUnits - $audioConfSku.ConsumedUnits
    # Check the number of available Audio Conferencing licenses
    if ($availableAudioConf -gt 0) {
        try {
            $msolUser = Get-MsolUser -UserPrincipalName $UserPrincipalName -ErrorAction Stop
            Write-Host "There are $availableAudioConf Audio Conferencing licenses available." -ForegroundColor Green
            Write-Host "Assigning $($audioConfSku.AccountSkuId) to $($msolUser.DisplayName)"
            if ( -not ($msolUser.UsageLocation)) {
                Write-Warning "Usage Location is not set."
                $usageLocation = Read-Host -Prompt "Enter the Usage Location to assign, for example `'US`'"
                Set-MsolUser -ObjectId $msolUser.ObjectId -UsageLocation $usageLocation
                try {
                    Set-MsolUserLicense -ObjectId $msolUser.ObjectId -AddLicenses $audioConfSku.AccountSkuId -ErrorAction Stop
                } catch {
                    Write-Warning "License assignment failed for $($msolUser.UserPrincipalName)"
                    Write-Host $_.Exception.Message -ForegroundColor Red
                }
            }
        } catch {
            Write-Warning "$UserPrincipalName was not found"
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    } else {
        Write-Warning "Not enough available Audio Conferencing licenses."
    }
}
