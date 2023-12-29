
# Connect MgGraph
$scopes = @(
    "Organization.Read.All"
)
$mgContext = Get-MgContext
if ($mgContext) {
    if ((Compare-Object -ReferenceObject $mgContext.Scopes -DifferenceObject $scopes).SideIndicator -contains '=>') {
        Write-Warning "Missing required MgContext scopes - connecting with all required scopes"
        Disconnect-MgGraph; Connect-MgGraph -Scopes $scopes | Out-Null
    }
}
else {
    Connect-MgGraph -Scopes $scopes | Out-Null
    $mgContext = Get-MgContext
}

# Build license GUID hash table
Invoke-WebRequest -Uri "https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv" -OutFile $env:TEMP\SKU_Product_Names.csv
$licenseReference = Import-CSV $env:TEMP\SKU_Product_Names.csv | Group-Object -AsHashTable -Property GUID

# Find subscribed licences
$subscribedSku = @(Get-MgSubscribedSku)

# Loop through each subscribed SKU
$results = [System.Collections.ArrayList]@()
foreach ($sku in $subscribedSku) {
    $item = [PSCustomObject]@{
        SkuPartNumber = $sku.SkuPartNumber
        TotalQty      = $sku.PrepaidUnits.Enabled
        Consumed      = $sku.ConsumedUnits
        LockedOut     = $sku.PrepaidUnits.LockedOut
        Suspended     = $sku.PrepaidUnits.Suspended
        Warning       = $sku.PrepaidUnits.Warning
        Available     = ($sku.PrepaidUnits.Enabled - ($sku.ConsumedUnits + $sku.PrepaidUnits.LockedOut + $sku.PrepaidUnits.Suspended + $sku.PrepaidUnits.Warning))
        Description   = ($licenseReference[$sku.SkuId]).Product_Display_Name[0]
    }
    [void]$results.Add($item)
}

# Output to screen
$results | ft -AutoSize
