function VoiceProps {
    [CmdletBinding()]Param(
        [Parameter(mandatory=$true)][String]$UserPrincipalName,
        [Parameter(mandatory=$false)][Switch]$Join
    )
    $userProperties = @()
    try {
        $csOnlineUser = Get-CsOnlineUser -Identity $UserPrincipalName -ErrorAction Stop
        $groupPolicyAssignments = EnumGroupPolicyAssignment
        $userGroupPolicyAssignments = $groupPolicyAssignments | ? {$_.UserPrincipalName -eq "$UserPrincipalName"} | Sort-Object
        if ($csOnlineUser.AssignedPlan) {
            $assignedPlans = @()
            foreach ($assignedPlan in $csOnlineUser.AssignedPlan) {
                $assignedPlans += [PSCustomObject]@{
                    Capability = $assignedPlan.Capability
                    CapabilityStatus = $assignedPlan.CapabilityStatus
                    ServicePlanId = $assignedPlan.ServicePlanId
                }
            }
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
            AssignedPlan = $assignedPlans
            Identity = $csOnlineUser.Identity
            GroupPolicyAssignments = $userGroupPolicyAssignments
        }
        $userProperties | Select-Object DisplayName,UserPrincipalName,SipAddress,EnterpriseVoiceEnabled,OnPremLineURI,LineUri,NumberType,OnlineVoiceRoutingPolicy,TenantDialPlan,TeamsCallingPolicy,TeamsMeetingPolicy,TeamsMeetingBroadcastPolicy,TeamsUpgradeEffectiveMode,RegistrarPool,UsageLocation,AssignedPlan,Identity,GroupPolicyAssignments
    } catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}
