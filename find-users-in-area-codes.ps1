$areaCodes = @("949","714")
$areaCodeUsers = @()
foreach ($areaCode in $areaCodes) {
    $usersInAreaCode = Get-CsOnlineUser | Where-Object {$_.LineUri -like "tel:+1$areaCode*"}
    foreach ($user in $usersInAreaCode) {$areaCodeUsers += $usersInAreaCode | Where-Object {$_.UserPrincipalName -eq $user.UserPrincipalName} | Select-Object DisplayName,UserPrincipalName,LineUri}
}
$areaCodeUsers | ft -AutoSize
