$tenant = "lab"
if (-not $tenant) {
    $tenant = ((Read-Host -Prompt "Enter the name of the Tenant...") -Replace '[\W]','').Trim()
}
$timeStamp = Get-Date -Format "yyyy-dd-MM-HHmmss"
$msolUsers = Get-MsolUser -All
$msolUsers | ForEach-Object -PV user {$_} | ForEach-Object {
    if ($user.ProxyAddresses) {
        $primarySMTP = (($user.ProxyAddresses | Where-Object {$_ -clike "SMTP*"}) -replace "SMTP:")
        $user | Add-Member -NotePropertyName PrimarySMTP -NotePropertyValue $primarySMTP
        $otherSMTP = ((($user.ProxyAddresses | Where-Object {$_ -clike "smtp*"}) -replace "smtp:" | Sort-Object) -join ";")
        $user | Add-Member -NotePropertyName OtherSMTP -NotePropertyValue $otherSMTP
    }
}
$msolUsers | Select-Object DisplayName,UserPrincipalName,PrimarySMTP,OtherSMTP,PhoneNumber,IsLicensed,UsageLocation,Country,State,City,Office,Department,Title,ObjectId | Export-Csv -Path "$PWD\$($tenant)_msolusers_smtp_$($timeStamp).csv" -NoTypeInformation
$msolUsers | ConvertTo-Json -Depth 100 | Out-File -FilePath "$PWD\$($tenant)_msolusers_smtp_$($timeStamp).json"
