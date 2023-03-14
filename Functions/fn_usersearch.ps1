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

# Find (even more) Enterprise Voice related attributes for a user based on any provided attribute
Function csouvp {
    [CmdletBinding()]Param([string]$prop,[string]$search)
    $userProperties = @()
    $users = Get-CsOnlineUser | ? {$_.$prop -like $search} | Sort-Object UserPrincipalName
    $groupPolicyAssignments = EnumGroupPolicyAssignment
    foreach ($user in $users) {
        $userGroupPolicyAssignments = $groupPolicyAssignments | ? {$_.UserPrincipalName -eq "$($user.UserPrincipalName)"} | Sort-Object
        if ($user.AssignedPlan) {
            $assignedPlans = @()
            foreach ($assignedPlan in $user.AssignedPlan) {
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
        if ($user.LineUri) {
            $numberType = (Get-CsPhoneNumberAssignment -TelephoneNumber ($user.LineUri -replace "tel:")).NumberType
        }
        else {
            $numberType = $null
        }
        $userProperties = [PSCustomObject]@{
            DisplayName                 = $user.DisplayName
            UserPrincipalName           = $user.UserPrincipalName
            SipAddress                  = $user.SipAddress
            EnterpriseVoiceEnabled      = $user.EnterpriseVoiceEnabled
            OnPremLineURI               = $user.OnPremLineURI
            LineUri                     = $user.LineUri
            NumberType                  = $numberType
            OnlineVoiceRoutingPolicy    = $user.OnlineVoiceRoutingPolicy
            TenantDialPlan              = $user.TenantDialPlan
            TeamsCallingPolicy          = $user.TeamsCallingPolicy
            TeamsMeetingPolicy          = $user.TeamsMeetingPolicy
            TeamsMeetingBroadcastPolicy = $user.TeamsMeetingBroadcastPolicy
            TeamsUpgradeEffectiveMode   = $user.TeamsUpgradeEffectiveMode
            UsageLocation               = $user.UsageLocation
            AssignedPlan                = $assignedPlans
            Identity                    = $user.Identity
            GroupPolicyAssignments      = $userGroupPolicyAssignments
        }
        $userProperties | Select-Object DisplayName,UserPrincipalName,SipAddress,EnterpriseVoiceEnabled,OnPremLineURI,LineUri,NumberType,OnlineVoiceRoutingPolicy,TenantDialPlan,TeamsCallingPolicy,TeamsMeetingPolicy,TeamsMeetingBroadcastPolicy,TeamsUpgradeEffectiveMode,UsageLocation,AssignedPlan,Identity,GroupPolicyAssignments
    }
}

