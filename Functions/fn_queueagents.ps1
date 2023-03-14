Function QueueAgents {
    Param([Parameter(mandatory=$false)][String]$Name)
    $queueAgents = @()
    try {
        $queues = @()
        if ($Name) {
            $queues = Get-CsCallQueue -NameFilter $Name -WarningAction SilentlyContinue
        } else {
            $queues = Get-CsCallQueue -WarningAction SilentlyContinue
        }
        foreach ($queue in $queues) {
            $agents = $queues.Agents
            foreach ($agent in $agents) {
                $csOnlineUser = Get-CsOnlineUser -Identity $agent.ObjectId
                # Add-Member -InputObject $agent -MemberType NoteProperty -Name DisplayName -Value $csOnlineUser.DisplayName
                # Add-Member -InputObject $agent -MemberType NoteProperty -Name UserPrincipalName -Value $csOnlineUser.UserPrincipalName
                $queueAgents += [PSCustomObject]@{
                    CallQueue         = $queue.Name
                    Identity          = $queue.Identity
                    RoutingMethod     = $queue.RoutingMethod
                    Statistics        = $queue.Statistics
                    DistributionLists = $queue.DistributionLists
                    AgentAlertTime    = $queue.AgentAlertTime
                    TimeoutThreshold  = $queue.TimeoutThreshold
                    OverflowThreshold = $queue.OverflowThreshold
                    Agent             = $csOnlineUser.DisplayName
                    UserPrincipalName = $csOnlineUser.UserPrincipalName
                    OptIn             = $agent.OptIn
                    AgentId           = $agent.ObjectId
                }
            }
        }
        $queueAgents  # | Select-Object CallQueue,QueueAssignment,GroupName,UserDisplayName,UserSipAddress | Sort-Object -Property @{Expression="CallQueue"},@{Expression="GroupName"},@{Expression="UserDisplayName"} | Format-Table
    }
    catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

