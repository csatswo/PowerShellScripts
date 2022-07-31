function SMTPAddressDump {
    [CmdletBinding()]Param(
        [Parameter(mandatory=$true)][String]$UserPrincipalName,
        [Parameter(mandatory=$false)][Bool]$Join
    )
    $msolUser = Get-MsolUser -UserPrincipalName $UserPrincipalName
    $proxyAddresses = $msolUser.ProxyAddresses
    $primarySMTP = (($proxyAddresses | ? {$_ -clike "SMTP*"}) -replace "SMTP:")
    if ($Join -eq $true) {
        Write-Host "Enter the join character(s): " -ForegroundColor Cyan -NoNewline
        $joinChars = Read-Host
        $otherSMTP = ((($proxyAddresses | ? {$_ -clike "smtp*"}) -replace "smtp:" | Sort-Object) -join "$joinChars")
    } else {
        $otherSMTP = (($proxyAddresses | ? {$_ -clike "smtp*"}) -replace "smtp:" | Sort-Object)
    }
    $results += [PSCustomObject]@{
        UserPrincipalName = $msolUser.UserPrincipalName
        PrimarySMTP = $primarySMTP
        OtherSMTP = $otherSMTP
        }
    $results
}
