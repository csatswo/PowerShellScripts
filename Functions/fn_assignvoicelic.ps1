Function AssignPS {
    [CmdletBinding()]Param(
        [string]$UserPrincipalName
    )
    # Get licenses SKUs for Phone System
    $msolAccountSkus = Get-MsolAccountSku
    $phoneSystemSku = $msolAccountSkus | ? {$_.AccountSkuId -like "*MCOEV*"}
    # Get number of available licenses
    $availablePhoneSystem = $phoneSystemSku.ActiveUnits - $phoneSystemSku.ConsumedUnits
    # Check the number of available Phone System licenses
    if ($availablePhoneSystem -gt 0) { 
        $msolUser = Get-MsolUser -UserPrincipalName $UserPrincipalName
        Write-Host "There are $availablePhoneSystem Phone System licenses available." -ForegroundColor Green
        Write-Host "Assigning $($phoneSystemSku.AccountSkuId) to $($msolUser.DisplayName)"
        Set-MsolUserLicense -ObjectId $msolUser.ObjectId -AddLicenses $phoneSystemSku.AccountSkuId
    } else {
        Write-Warning "Not enough available Phone System licenses."
    }
}

Function AssignAC {
    [CmdletBinding()]Param(
        [string]$UserPrincipalName
    )
    # Get licenses SKUs for Phone System
    $msolAccountSkus = Get-MsolAccountSku
    $audioConfSku = $msolAccountSkus | ? {$_.AccountSkuId -like "*MCOMEETADV*"}
    # Get number of available licenses
    $availableAudioConf = $audioConfSku.ActiveUnits - $audioConfSku.ConsumedUnits
    # Check the number of available Phone System licenses
    if ($availableAudioConf -gt 0) { 
        $msolUser = Get-MsolUser -UserPrincipalName $UserPrincipalName
        Write-Host "There are $availableAudioConf Audio Conferencing licenses available." -ForegroundColor Green
        Write-Host "Assigning $($audioConfSku.AccountSkuId) to $($msolUser.DisplayName)"
        Set-MsolUserLicense -ObjectId $msolUser.ObjectId -AddLicenses $audioConfSku.AccountSkuId
    } else {
        Write-Warning "Not enough available Audio Conferencing licenses."
    }
}

Function AssignCAP {
    [CmdletBinding()]Param(
        [string]$UserPrincipalName
    )
    # Get licenses SKUs for Phone System
    $msolAccountSkus = Get-MsolAccountSku
    $commonAreaSku = $msolAccountSkus | ? {$_.AccountSkuId -like "*MCOCAP*"}
    # Get number of available licenses
    $availableCommonArea = $commonAreaSku.ActiveUnits - $commonAreaSku.ConsumedUnits
    # Check the number of available Phone System licenses
    if ($availableCommonArea -gt 0) { 
        $msolUser = Get-MsolUser -UserPrincipalName $UserPrincipalName
        Write-Host "There are $availableCommonArea Common Area Phone licenses available." -ForegroundColor Green
        Write-Host "Assigning $($commonAreaSku.AccountSkuId) to $($msolUser.DisplayName)"
        Set-MsolUserLicense -ObjectId $msolUser.ObjectId -AddLicenses $commonAreaSku.AccountSkuId
    } else {
        Write-Warning "Not enough available Common Area Phone licenses."
    }
}

Function AssignVU {
    [CmdletBinding()]Param(
        [string]$UserPrincipalName
    )
    # Get licenses SKUs for Phone System
    $msolAccountSkus = Get-MsolAccountSku
    $virtualUserSku = $msolAccountSkus | ? {$_.AccountSkuId -like "*PHONESYSTEM_VIRTUALUSER*"}
    # Get number of available licenses
    $availableVirtualUser = $virtualUserSku.ActiveUnits - $virtualUserSku.ConsumedUnits
    # Check the number of available Phone System licenses
    if ($availableVirtualUser -gt 0) { 
        $msolUser = Get-MsolUser -UserPrincipalName $UserPrincipalName
        Write-Host "There are $availableVirtualUser Virtual User licenses available." -ForegroundColor Green
        Write-Host "Assigning $($virtualUserSku.AccountSkuId) to $($msolUser.DisplayName)"
        Set-MsolUserLicense -ObjectId $msolUser.ObjectId -AddLicenses $virtualUserSku.AccountSkuId
    } else {
        Write-Warning "Not enough available Virtual User licenses."
    }
}
