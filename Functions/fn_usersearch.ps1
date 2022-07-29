# Find a user based on any provided attribute
Function csou {
    [CmdletBinding()]Param([string]$prop,[string]$search)
    $users = Get-CsOnlineUser | ? {$_.$prop -like $search} | Sort-Object UserPrincipalName | Select-Object DisplayName,UserPrincipalName
    $users
}

# Find Enterprise Voice related attributes for a user based on any provided attribute
Function csouev {
    [CmdletBinding()]Param([string]$prop,[string]$search)
    $users = Get-CsOnlineUser | ? {$_.$prop -like $search} | Sort-Object UserPrincipalName | Select-Object DisplayName,UserPrincipalName,SipAddress,EnterpriseVoiceEnabled,LineUri,OnlineVoiceRoutingPolicy,TenantDialPlan,TeamsUpgradeEffectiveMode,UsageLocation
    foreach ($user in $users) {
        if ($user.LineUri) {
            $user | Add-Member -NotePropertyName NumberType -NotePropertyValue (Get-CsPhoneNumberAssignment -TelephoneNumber ($user.LineUri -replace "tel:")).NumberType
        }
    }
    $users
}