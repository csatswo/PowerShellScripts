Function EnumGroupPolicyAssignment {
    [CmdletBinding()]Param(
        [Parameter(mandatory=$false)][String]$UserPrincipalName
    )
    $results = @()
    $groupPolicyAssignments = Get-CsGroupPolicyAssignment
    foreach ($groupPolicyAssignment in $groupPolicyAssignments[0]) {
        $group = Get-MsolGroup -ObjectId $groupPolicyAssignment.GroupId -ErrorAction SilentlyContinue
        if ($group) {
            $groupMembers = Get-MsolGroupMember -All -GroupObjectId $groupPolicyAssignment.GroupId -ErrorAction SilentlyContinue
            if ($groupMembers) {
                foreach ($groupMember in $groupMembers)  {
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
    }
    if ($UserPrincipalName) {
        $results | Where-Object {$_.UserPrincipalName -eq $UserPrincipalName} | Sort-Object PolicyType,Rank,UserPrincipalName | Select-Object PolicyType,PolicyName,Rank,Group,DisplayName,UserPrincipalName
    } else {
        $results | Sort-Object PolicyType,Rank,UserPrincipalName | Select-Object PolicyType,PolicyName,Rank,Group,DisplayName,UserPrincipalName
    }
}
