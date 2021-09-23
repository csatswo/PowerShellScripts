Function msol {
    Import-Module MSOnline;Connect-MsolService | Out-Null
}

Function aad {
    Import-Module AzureADPreview;Connect-AzureAD | Out-Null
}

Function teams {
    Import-Module MicrosoftTeams;Connect-MicrosoftTeams| Out-Null
}

Function exo {
    Import-Module ExchangeOnlineManagement;Connect-ExchangeOnline -ShowBanner:$false
}

Function m365mfa {
    Write-Host "Connecting to MSOnline..."
    msol
    Write-Host "Connecting to AzureAD..."
    aad
    Write-Host "Connecting to Teams..."
    teams
    Write-Host "Connecting to ExchangeOnline..."
    exo
    $Host.UI.RawUI.WindowTitle = "$((Get-MsolDomain | Where-Object {$_.isDefault}).name)"
    Set-Location C:\Temp
}

Function m365 {
    $Credential  = Get-Credential
    Write-Host "Connecting to MSOnline..."
    Import-Module MSOnline;Connect-MsolService -Credential $Credential | Out-Null
    Write-Host "Connecting to AzureAD..."
    Import-Module AzureADPreview;Connect-AzureAD -Credential $Credential | Out-Null
    Write-Host "Connecting to Teams..."
    Import-Module MicrosoftTeams;Connect-MicrosoftTeams -Credential $Credential | Out-Null
    Write-Host "Connecting to ExchangeOnline..."
    Import-Module ExchangeOnlineManagement;Connect-ExchangeOnline -Credential $Credential -ShowBanner:$false
    $Host.UI.RawUI.WindowTitle = "$((Get-MsolDomain | Where-Object {$_.isDefault}).name)"
    Set-Location C:\Temp
}
