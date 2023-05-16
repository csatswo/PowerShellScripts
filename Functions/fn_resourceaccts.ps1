Function ResourceAccts {
    $results = @()
    $date = Get-Date -Format yyyy-MM-dd
    $applicationEndpoints = Get-CsOnlineApplicationInstance
    foreach ($applicationEndpoint in $applicationEndpoints) {
        $csOnlineUser = Get-CsOnlineUser -Identity $applicationEndpoint.UserPrincipalName
        if ($csOnlineUser.AssignedPlan) {
            $assignedPlans = $csOnlineUser.AssignedPlan
        }
        else {
            $assignedPlans = $null
        }
        $results += [PSCustomObject]@{
            DisplayName        = $applicationEndpoint.DisplayName
            UserPrincipalName  = $applicationEndpoint.UserPrincipalName
            PhoneNumber        = $applicationEndpoint.PhoneNumber
            ApplicationId      = $applicationEndpoint.ApplicationId
            AssignedPlans      = $assignedPlans
        }
    }
    $results
}