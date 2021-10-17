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