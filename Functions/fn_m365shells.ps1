function iseTitle {
    $Host.UI.RawUI.WindowTitle = (Get-CsOnlineSipDomain | Where-Object {$_.Name -like "*.onmicrosoft.com" -and $_.Name -notlike "*.mail.onmicrosoft.com"}).Name
    Set-Location C:\Temp
}

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
    if ((Get-Host).Version -lt 5.2) { Import-Module ExchangeOnlineManagement ;Connect-ExchangeOnline -ShowBanner:$false }
    else { Import-Module ExchangeOnlineManagement;Connect-ExchangeOnline -UseWindowsPowerShell -ShowBanner:$false }
}

Function spo {
    $domain = ((Get-CsOnlineSipDomain | Where-Object {$_.Name -like "*.onmicrosoft.com" -and $_.Name -notlike "*.mail.onmicrosoft.com"}).Name) -replace "\.onmicrosoft\.com"
    $spoAdminUrl = "https://"+$domain+"-admin.sharepoint.com"
    if ((Get-Host).Version -lt 5.2) { Import-Module Microsoft.Online.SharePoint.PowerShell -WarningAction SilentlyContinue;Connect-SPOService -Url $spoAdminUrl }
    else { Import-Module Microsoft.Online.SharePoint.PowerShell -UseWindowsPowerShell -WarningAction SilentlyContinue;Connect-SPOService -Url $spoAdminUrl }
}

Function m365mfa {
    if ((Get-Host).Version -match '5.1') {
        Write-Host "Connecting to MSOnline..."
        msol
        Write-Host "Connecting to AzureAD..."
        aad
        Write-Host "Connecting to Teams..."
        teams
        Write-Host "Connecting to ExchangeOnline..."
        exo
        iseTitle
    }
    else {
        Write-Host "Not PowerShell 5.1, skipping MSOnline and AzureAD..." -ForegroundColor Yellow
        Write-Host "Connecting to Teams..."
        teams
        Write-Host "Connecting to ExchangeOnline..."
        exo
        iseTitle
    }
}

# Function m365 {
#     if ((Get-Host).Version -match '5.1') {
#         $Credential  = Get-Credential
#         Write-Host "Connecting to MSOnline..."
#         Import-Module MSOnline;Connect-MsolService -Credential $Credential | Out-Null
#         Write-Host "Connecting to AzureAD..."
#         Import-Module AzureADPreview;Connect-AzureAD -Credential $Credential | Out-Null
#         Write-Host "Connecting to Teams..."
#         Import-Module MicrosoftTeams;Connect-MicrosoftTeams -Credential $Credential | Out-Null
#         Write-Host "Connecting to ExchangeOnline..."
#         Import-Module ExchangeOnlineManagement;Connect-ExchangeOnline -Credential $Credential -ShowBanner:$false
#         iseTitle
#     }
#     else {
#         $Credential  = Get-Credential
#         Write-Host "Not PowerShell 5.1, skipping MSOnline and AzureAD..." -ForegroundColor Yellow
#         Write-Host "Connecting to Teams..."
#         Import-Module MicrosoftTeams;Connect-MicrosoftTeams -Credential $Credential | Out-Null
#         Write-Host "Connecting to ExchangeOnline..."
#         Import-Module ExchangeOnlineManagement;Connect-ExchangeOnline -Credential $Credential -ShowBanner:$false
#         iseTitle
#     }
# }

Function refreshM365 {
    $modulesM365  = @("AzureADPreview","ExchangeOnlineManagement","Microsoft.Online.SharePoint.PowerShell","MicrosoftTeams","MSOnline")
    $modulesOther = @("ImportExcel")
    foreach ($moduleName in $modulesM365) {
        $installedModule = Get-Module -ListAvailable -Name $moduleName
        $availableModule = Find-Module -Repository PSGallery -Name $moduleName
        if ($installedModule) {
            if ($installedModule.Version -lt $availableModule.Version) {
                Write-Host "`n$($installedModule.Name) version is $($installedModule.Version)" -ForegroundColor Yellow
                Write-Host "Updating module to version $($availableModule.Version)" -ForegroundColor Yellow
                Uninstall-Module -Name $installedModule.Name -AllVersions
                Install-Module -Repository PSGallery -Name $availableModule.Name
            } else {
                Write-Host "`n$moduleName"
                Write-Host "Installed version is latest `($($installedModule.Version)`)" -ForegroundColor Green
            }
        } else {
            Write-Host "$($availableModule.Name) is not installed. Installing now..." -ForegroundColor Yellow
            Install-Module -Repository PSGallery -Name $availableModule.Name            
        }
    }
    foreach ($moduleName in $modulesOther) {
        $installedModule = Get-Module -ListAvailable -Name $moduleName
        $availableModule = Find-Module -Repository PSGallery -Name $moduleName
        if ($installedModule) {
            if ($installedModule.Version -lt $availableModule.Version) {
                Write-Host "`n$($installedModule.Name) version is $($installedModule.Version)" -ForegroundColor Yellow
                Write-Host "Updating module to version $($availableModule.Version)" -ForegroundColor Yellow
                Uninstall-Module -Name $installedModule.Name -AllVersions
                Install-Module -Repository PSGallery -Name $availableModule.Name
            } else {
                Write-Host "`n$moduleName"
                Write-Host "Installed version is latest `($($installedModule.Version)`)" -ForegroundColor Green
            }
        } else {
            Write-Host "$($availableModule.Name) is not installed. Installing now..." -ForegroundColor Yellow
            Install-Module -Repository PSGallery -Name $availableModule.Name            
        }
    }
    Update-Module
}
