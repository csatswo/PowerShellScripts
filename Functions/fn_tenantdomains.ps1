Function TenantDomains {
if (Get-MsolDomain -ErrorAction SilentlyContinue) {
    $msolDomains = Get-MsolDomain
    $msolDefaultDomain = ($msolDomains | Where-Object {$_.IsDefault -eq $true}).Name
    $msolVanityDomains = ($msolDomains | Where-Object {$_.Name -notlike "*.onmicrosoft.com" -and $_.Name -notlike "*mail.onmicrosoft.com"})
    $msolTenantDomain = ($msolDomains | Where-Object {$_.Name -like "*.onmicrosoft.com" -and $_.Name -notlike "*mail.onmicrosoft.com"}).Name
} else {
    $msolDefaultDomain = "Not Connected"
    $msolTenantDomain = "Not Connected"
    $msolVanityDomains = "Not Connected"
}
try {
    $aadDomains = Get-AzureADDomain -ErrorAction SilentlyContinue
    $aadTenantDomain = ($aadDomains | Where-Object {$_.Name -like "*.onmicrosoft.com" -and $_.Name -notlike "*mail.onmicrosoft.com"}).Name
} catch {
    $aadTenantDomain = "Not Connected"
}
try {
    $teamsDomains = Get-CsOnlineSipDomain -ErrorAction SilentlyContinue
    $teamsTenantDomain = ($teamsDomains | Where-Object {$_.Name -like "*.onmicrosoft.com" -and $_.Name -notlike "*mail.onmicrosoft.com"}).Name
} catch {
    $teamsTenantDomain = "Not Connected"
}
try {
    $exoDomains = Get-AcceptedDomain -ErrorAction SilentlyContinue
    $exoTenantDomain = ($exoDomains | Where-Object {$_.DomainName -like "*.onmicrosoft.com" -and $_.Name -notlike "*mail.onmicrosoft.com"}).Name
} catch {
    $exoTenantDomain = "Not Connected"
}
Write-Host "`nMSOL Default Domain: $msolDefaultDomain"
Write-Host "MSOL Tenant Domain:  $msolTenantDomain"
Write-Host "AAD Tenant Domain:   $aadTenantDomain"
Write-Host "Teams Tenant Domain: $teamsTenantDomain"
Write-Host "ExO Tenant Domain:   $exoTenantDomain"
Write-Host "`nAll vanity domains:"
$msolVanityDomains | Sort-Object Name
}