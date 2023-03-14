Function LicenseReport {
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
