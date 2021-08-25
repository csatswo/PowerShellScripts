Function LicenseReport {
$finddomain = Get-AzureADDomain | ? {$_.Name -like "*.onmicrosoft.com" -and $_.Name -notlike "*.mail.onmicrosoft.com"}
$domain = $finddomain.Name
$domain -match '(?<content>.*).onmicrosoft.com' | Out-Null
$subDomain = $matches['content']
$subscribedSku = @()
$azureSkus = Get-AzureADSubscribedSku 
foreach ($azureSku in $azureSkus) {
    $msolSku = Get-MsolSubscription | ? {$_.SkuPartNumber -eq $azureSku.SkuPartNumber -and $_.Status -ne "LockedOut"}
    $totalQty = 0
    foreach ($sku in $msolSku) {
        $totalQty += [int]$Sku.TotalLicenses
        }
    $availableQty = $totalQty - [int]$azureSku.ConsumedUnits
    $subscribedSkuProps = @{
        SkuPartNumber = "$($subdomain):$($azureSku.SkuPartNumber)"
        TotalQty = $totalQty
        Consumed = $azureSku.ConsumedUnits
        Available = $availableQty
        }
    $subscribedSkuProperties = New-Object -TypeName PSObject -Property $subscribedSkuProps
    $subscribedSku += $subscribedSkuProperties
    }
$subscribedSku | Select-Object SkuPartNumber,TotalQty,Consumed,Available | FT
}