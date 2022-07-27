Function EnumGroupPolicyAssignment {
    $results = @()
    $groupPolicyAssignments = Get-CsGroupPolicyAssignment
    foreach ($groupPolicyAssignment in $groupPolicyAssignments) {
        $group = Get-MsolGroup -ObjectId $groupPolicyAssignment.GroupId
        $groupMembers = Get-MsolGroupMember -GroupObjectId $groupPolicyAssignment.GroupId
        if ($groupMembers) {
            foreach ($groupMember in $groupMembers) {
                $results += [PSCustomObject]@{
                    PolicyType = $groupPolicyAssignment.PolicyType
                    PolicyName = $groupPolicyAssignment.PolicyName
                    Rank = $groupPolicyAssignment.Priority
                    Group = $group.DisplayName
                    DisplayName = $groupMember.DisplayName
                    UserPrincipalName = $groupMember.EmailAddress
                }
            }
        } else {
            $results += [PSCustomObject]@{
                PolicyType = $groupPolicyAssignment.PolicyType
                PolicyName = $groupPolicyAssignment.PolicyName
                Rank = $groupPolicyAssignment.Priority
                Group = $group.DisplayName
                DisplayName = $null
                UserPrincipalName = $null
            }   
        }
    }
    $results | Sort-Object PolicyType,Rank,UserPrincipalName | Select-Object PolicyType,PolicyName,Rank,Group,DisplayName,UserPrincipalName
}