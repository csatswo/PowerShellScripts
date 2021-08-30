Function teams {
    Import-Module MicrosoftTeams;Connect-MicrosoftTeams| Out-Null
}

Function exo {
    Import-Module ExchangeOnlineManagement;Connect-ExchangeOnline -ShowBanner:$false
}

Function aad {
    Import-Module AzureADPreview;Connect-AzureAD | Out-Null
}

Function msol {
    Import-Module MSOnline;Connect-MsolService | Out-Null
}

Function m365 {
    msol;aad;teams;exo
}
