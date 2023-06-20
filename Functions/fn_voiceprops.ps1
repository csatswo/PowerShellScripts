function VoiceProps {
    [CmdletBinding()]Param([Parameter(mandatory=$true)][String]$UserPrincipalName)
    $userProperties = @()
    try {
        $csOnlineUser = Get-CsOnlineUser -Identity $UserPrincipalName -ErrorAction Stop
        if ($csOnlineUser.AssignedPlan) {
            $assignedPlans = @()
            $csOnlineUser.ProvisionedPlan | foreach { $assignedPlans += [String]($_.Capability + ":" + $_.CapabilityStatus) }
        }
        else {
            $assignedPlans = $null
        }
        if ($csOnlineUser.LineUri) {
            $numberType = (Get-CsPhoneNumberAssignment -TelephoneNumber ($csOnlineUser.LineUri -replace "tel:")).NumberType
        }
        else {
            $numberType = $null
        }
        $userProperties = [PSCustomObject]@{
            DisplayName = $csOnlineUser.DisplayName
            UserPrincipalName = $csOnlineUser.UserPrincipalName
            SipAddress = $csOnlineUser.SipAddress
            EnterpriseVoiceEnabled = $csOnlineUser.EnterpriseVoiceEnabled
            OnPremLineURI = $csOnlineUser.OnPremLineURI
            LineUri = $csOnlineUser.LineUri
            NumberType = $numberType
            OnlineVoiceRoutingPolicy = $csOnlineUser.OnlineVoiceRoutingPolicy
            TenantDialPlan = $csOnlineUser.TenantDialPlan
            TeamsCallingPolicy = $csOnlineUser.TeamsCallingPolicy
            TeamsMeetingPolicy = $csOnlineUser.TeamsMeetingPolicy
            TeamsMeetingBroadcastPolicy = $csOnlineUser.TeamsMeetingBroadcastPolicy
            TeamsUpgradeEffectiveMode = $csOnlineUser.TeamsUpgradeEffectiveMode
            RegistrarPool = $csOnlineUser.RegistrarPool
            UsageLocation = $csOnlineUser.UsageLocation
            AssignedPlan = $assignedPlans -join "|"
            Identity = $csOnlineUser.Identity
        }
        $userProperties | Select-Object DisplayName,UserPrincipalName,SipAddress,EnterpriseVoiceEnabled,OnPremLineURI,LineUri,NumberType,OnlineVoiceRoutingPolicy,TenantDialPlan,TeamsCallingPolicy,TeamsMeetingPolicy,TeamsMeetingBroadcastPolicy,TeamsUpgradeEffectiveMode,RegistrarPool,UsageLocation,AssignedPlan,Identity
    } catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}
