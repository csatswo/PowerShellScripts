<#
.SYNOPSIS

    Export-M365Licenses.ps1
    This script will display subscribed licences and quantities.

.DESCRIPTION
    
    Author: csatswo
    This script outputs to the terminal a table of subscribed Office 365 licenses and exports a CSV with the data.
    Assumes active sessions with MSOnline (Connect-MsolService) and AzureAD (Connect-AzureAD).

.PARAMETER Path

    The path for the exported CSV. For example: "C:\Temp\licenses.csv"

.EXAMPLE 
    
    .\Export-M365Licenses.ps1 -Path C:\Temp\licenses.csv
#>

Param(
    [Parameter(mandatory=$true)][String]$Path
)

# Try to find the '*.onmicrosoft.com' domain
$finddomain = Get-AzureADDomain | Where-Object {$_.Name -like "*.onmicrosoft.com" -and $_.Name -notlike "*.mail.onmicrosoft.com"}
$domain = $finddomain.Name
$domain -match '(?<content>.*).onmicrosoft.com' | Out-Null
$subDomain = $matches['content']

# Build license SKU hash table
Invoke-WebRequest -Uri "https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv" -OutFile $env:TEMP\SKU_Product_Names.csv
$licenseReference = Import-CSV $env:TEMP\SKU_Product_Names.csv | Group-Object -AsHashTable -Property GUID

# Find subscribed licences
$subscribedSku = @()
$azureSkus = Get-AzureADSubscribedSku 

# Loop through each subscribed SKU
foreach ($azureSku in $azureSkus) {
    $msolSku = Get-MsolSubscription | Where-Object {$_.SkuPartNumber -eq $azureSku.SkuPartNumber -and $_.Status -ne "LockedOut"}
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
        Description = ($licenseReference[$azureSku.SkuId]).Product_Display_Name[0]
        }
    $subscribedSkuProperties = New-Object -TypeName PSObject -Property $subscribedSkuProps
    $subscribedSku += $subscribedSkuProperties
}

# Output to screen
$subscribedSku | Select-Object SkuPartNumber,TotalQty,Consumed,Available,Description | Format-Table -AutoSize

# Export to CSV
$subscribedSku | Select-Object SkuPartNumber,TotalQty,Consumed,Available,Description | Export-Csv -Path $Path -NoTypeInformation
Write-Host "`nExport saved to $Path" -ForegroundColor Cyan
