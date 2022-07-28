function SMTPAddressDump {
    [CmdletBinding()]Param(
        [Parameter(mandatory=$true)][String]$UserPrincipalName
    )
    $msolUser = Get-MsolUser -UserPrincipalName $UserPrincipalName
    $proxyAddresses = $msolUser.ProxyAddresses
    $primarySMTP = (($proxyAddresses | ? {$_ -clike "SMTP*"}) -replace "SMTP:")
    $otherSMTP = (($proxyAddresses | ? {$_ -clike "smtp*"}) -replace "smtp:")
    $results += [PSCustomObject]@{
        UserPrincipalName = $msolUser.UserPrincipalName
        PrimarySMTP = $primarySMTP
        OtherSMTP = $otherSMTP
        }
    $results
}