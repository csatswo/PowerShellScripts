Function LicenseReport {
    $subscribedSku = @()
    $domain = ((Get-AzureADDomain | Where-Object {$_.Name -like "*.onmicrosoft.com" -and $_.Name -notlike "*.mail.onmicrosoft.com"}).Name) -replace "\.onmicrosoft\.com"
    $azureSkus = Get-AzureADSubscribedSku
    foreach ($azureSku in $azureSkus) {
        $msolSku = Get-MsolSubscription | Where-Object {$_.SkuPartNumber -eq $azureSku.SkuPartNumber -and $_.Status -ne "LockedOut" -and $_.Status -ne "Suspended"}
        $totalQty = 0
        foreach ($sku in $msolSku) {
            $totalQty += [int]$Sku.TotalLicenses
        }
        $availableQty = $totalQty - [int]$azureSku.ConsumedUnits
        $subscribedSku += [PSCustomObject]@{
            SkuPartNumber = "$($domain):$($azureSku.SkuPartNumber)"
            TotalQty = $totalQty
            Consumed = $azureSku.ConsumedUnits
            Available = $availableQty
        }
    }
    $subscribedSku | Select-Object SkuPartNumber,TotalQty,Consumed,Available
}
Function LicenseReport2 {
    $subscribedSku = @()
    $domain = ((Get-AzureADDomain | Where-Object {$_.Name -like "*.onmicrosoft.com" -and $_.Name -notlike "*.mail.onmicrosoft.com"}).Name) -replace "\.onmicrosoft\.com"
    $azureSkus = Get-AzureADSubscribedSku
    foreach ($azureSku in $azureSkus) {
        $totalQty = [int]$azureSku.PrepaidUnits.Enabled
        $availableQty = $totalQty - [int]$azureSku.ConsumedUnits
        $subscribedSku += [PSCustomObject]@{
            SkuPartNumber = "$($domain):$($azureSku.SkuPartNumber)"
            TotalQty = $totalQty
            Consumed = $azureSku.ConsumedUnits
            Available = $availableQty
        }
    }
    $subscribedSku | Select-Object SkuPartNumber,TotalQty,Consumed,Available
}
