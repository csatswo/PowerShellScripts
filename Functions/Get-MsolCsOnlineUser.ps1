Function Get-MsolCsOnlineUser {
    [CmdletBinding()]Param(
        [string]$UserPrincipalName
    )
    $csOnlineMsolUser = New-Object -TypeName PSObject
    (Get-CsOnlineUser -Identity $UserPrincipalName),(Get-MsolUser -UserPrincipalName $UserPrincipalName | Select-Object isLicensed,Licenses) | ForEach-Object {$msolUser = $_; $msolUser | Get-Member -MemberType Property,NoteProperty | ForEach-Object {$csOnlineMsolUser | Add-Member -NotePropertyMembers @{$_.Name=$msolUser.($_.Name)} -Force}}
    $csOnlineMsolUser
}
