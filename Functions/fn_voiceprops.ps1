function VoiceProps {
    [CmdletBinding()]Param(
        [Parameter(mandatory=$true)][String]$UserPrincipalName,
        [Parameter(mandatory=$false)][Bool]$Join
    )
    $userProperties = @()
    $msolUser = Get-MsolUser -UserPrincipalName $UserPrincipalName -ErrorAction SilentlyContinue
    $csOnlineUser = Get-CsOnlineUser -Identity $UserPrincipalName -ErrorAction SilentlyContinue
    $groupPolicyAssignments = EnumGroupPolicyAssignment
    $userGroupPolicyAssignments = $groupPolicyAssignments | ? {$_.UserPrincipalName -eq "$UserPrincipalName"} | Sort-Object
    if ($msolUser.IsLicensed -eq $true) {
        $licenses = $msolUser.Licenses.AccountSkuId
    } else {
        $licenses = $null
    }
    if ($Join -eq $true) {
        Write-Host "Enter the join character(s): " -ForegroundColor Cyan -NoNewline
        $joinChars = Read-Host
        $licenses = (($licenses | Sort-Object) -join "$joinChars")
    }
    $userProperties = [PSCustomObject]@{
        DisplayName = $csOnlineUser.DisplayName
        UserPrincipalName = $csOnlineUser.UserPrincipalName
        SipAddress = $csOnlineUser.SipAddress
        EnterpriseVoiceEnabled = $csOnlineUser.EnterpriseVoiceEnabled
        OnPremLineURI = $csOnlineUser.OnPremLineURI
        LineUri = $csOnlineUser.LineUri
        OnlineVoiceRoutingPolicy = $csOnlineUser.OnlineVoiceRoutingPolicy
        TenantDialPlan = $csOnlineUser.TenantDialPlan
        TeamsCallingPolicy = $csOnlineUser.TeamsCallingPolicy
        TeamsMeetingPolicy = $csOnlineUser.TeamsMeetingPolicy
        TeamsMeetingBroadcastPolicy = $csOnlineUser.TeamsMeetingBroadcastPolicy
        TeamsUpgradeEffectiveMode = $csOnlineUser.TeamsUpgradeEffectiveMode
        RegistrarPool = $csOnlineUser.RegistrarPool
        UsageLocation = $csOnlineUser.UsageLocation
        isLicensed = $msolUser.isLicensed
        Licenses = $licenses
        ObjectId = $msolUser.ObjectId
        GroupPolicyAssignments = $userGroupPolicyAssignments
    }
    $userProperties | Select-Object DisplayName,UserPrincipalName,SipAddress,EnterpriseVoiceEnabled,OnPremLineURI,LineUri,OnlineVoiceRoutingPolicy,TenantDialPlan,TeamsCallingPolicy,TeamsMeetingPolicy,TeamsMeetingBroadcastPolicy,TeamsUpgradeEffectiveMode,RegistrarPool,UsageLocation,isLicensed,Licenses,ObjectId,GroupPolicyAssignments
}
