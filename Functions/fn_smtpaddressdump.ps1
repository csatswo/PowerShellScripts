function SMTPUserAddressDump {
    [CmdletBinding()]Param(
        [Parameter(mandatory=$true)][String]$UserPrincipalName,
        [Parameter(mandatory=$false)][Bool]$Join
    )
    try {
        $azureADUser = Get-AzureADUser -Filter "userPrincipalName eq '$UserPrincipalName'" -ErrorAction Stop
        $proxyAddresses = $azureADUser.ProxyAddresses
        $primarySMTP = (($proxyAddresses | ? {$_ -clike "SMTP*"}) -replace "SMTP:")
        if ($Join -eq $true) {
            Write-Host "Enter the join character(s): " -ForegroundColor Cyan -NoNewline
            $joinChars = Read-Host
            $otherSMTP = ((($proxyAddresses | ? {$_ -clike "smtp*"}) -replace "smtp:" | Sort-Object) -join "$joinChars")
        } else {
            $otherSMTP = (($proxyAddresses | ? {$_ -clike "smtp*"}) -replace "smtp:" | Sort-Object)
        }
        $results += [PSCustomObject]@{
            UserType = $azureADUser.UserType
            DisplayName = $azureADUser.DisplayName
            UserPrincipalName = $azureADUser.UserPrincipalName
            PrimarySMTP = $primarySMTP
            OtherSMTP = $otherSMTP
            }
        $results | Select-Object UserType,DisplayName,UserPrincipalName,PrimarySMTP,OtherSMTP
    } catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}
function SMTPTenantAddressDump {
    [CmdletBinding()]Param(
        [Parameter(mandatory=$false)][Bool]$Join
    )
    Write-Warning -Message "This will run for every user and can be extremely slow."
    Read-Host -Prompt "Press `'Enter`' to proceed"
    $allUsers = Get-AzureADUser -All $true
    $results = @()
    foreach ($user in $allUsers) {
        $proxyAddresses = $user.ProxyAddresses
        $primarySMTP = (($proxyAddresses | ? {$_ -clike "SMTP*"}) -replace "SMTP:")
        if ($Join -eq $true) {
            Write-Host "Enter the join character(s): " -ForegroundColor Cyan -NoNewline
            $joinChars = Read-Host
            $otherSMTP = ((($proxyAddresses | ? {$_ -clike "smtp*"}) -replace "smtp:" | Sort-Object) -join "$joinChars")
        } else {
            $otherSMTP = (($proxyAddresses | ? {$_ -clike "smtp*"}) -replace "smtp:" | Sort-Object)
        }
        $results += [PSCustomObject]@{
            UserType = $user.UserType
            DisplayName = $user.DisplayName
            UserPrincipalName = $user.UserPrincipalName
            PrimarySMTP = $primarySMTP
            OtherSMTP = $otherSMTP
            }
    }
    $results | Select-Object UserType,DisplayName,UserPrincipalName,PrimarySMTP,OtherSMTP
}
