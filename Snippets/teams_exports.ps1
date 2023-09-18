$tenant = "demo"

$csOnlineUsers = Get-CsOnlineUser
$csOnlineUsers | ConvertTo-Json -Depth 100 | Out-File "C:\TEMP\$($tenant)_CsOnlineUsers_2023-09-17.json"

foreach ($policyType in (Get-Command get-cs*policy*)) {
    & $policyType | ConvertTo-Json -Depth 100 | Out-File "C:\TEMP\$($tenant)_$($policyType)_2023-09-17.json"
}
