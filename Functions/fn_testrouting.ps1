Function TestRouting {
    param([Parameter(mandatory=$true)][String]$UserPrincipalName,[Parameter(mandatory=$true)][String]$DialedNumber)
    begin {
        $voiceRoutes = @()
        $matchedVoiceRoutes = @()
        $allVoiceRoutes = Get-CsOnlineVoiceRoute
    }
    process {
        try {
            $userReturned = Get-CsOnlineUser -Identity $UserPrincipalName -ErrorAction Stop
            $userDisplayName = $userReturned.DisplayName
            if ($userReturned.TenantDialPlan) {
                $assignedDialPlans = @($userReturned.TenantDialPlan.Name,$($userReturned.DialPlan + " (Usage Location)"))
            } else {
                $assignedDialPlans = @("Global",$($userReturned.DialPlan + " (Usage Location)"))
            }
            $dialPlanTestResults = Test-CsEffectiveTenantDialPlan -DialedNumber $DialedNumber -Identity $userReturned.UserPrincipalName
            if ($dialPlanTestResults.TranslatedNumber) {
                $normalizedNumber = $dialPlanTestResults.TranslatedNumber
                # $matchingRule = [System.Collections.ArrayList]@()
                # $dialPlanTestResults.MatchingRule -split ";" | foreach { $matchingRule.Add(@{($_ -split "=")[0]=($_ -split "=")[1]}) }
                $matchingRule = (Get-CsTenantDialPlan -Identity $assignedDialPlans[0]).NormalizationRules | ? {$_.Name -eq (($dialPlanTestResults.MatchingRule).Substring(($dialPlanTestResults.MatchingRule).IndexOf("Name=") + 5) -split ";")[0]}
            } else {
                $normalizedNumber = $null
            }
            $UserOnlineVoiceRoutingPolicy = ($userReturned).OnlineVoiceRoutingPolicy
            if (!$userOnlineVoiceRoutingPolicy) { $userOnlineVoiceRoutingPolicy = "Global" }
            $pstnUsages = (Get-CsOnlineVoiceRoutingPolicy -Identity $userOnlineVoiceRoutingPolicy).OnlinePstnUsages
            foreach ($pstnUsage in $pstnUsages) {
                $voiceRoutes += $allVoiceRoutes | Where-Object {$_.OnlinePstnUsages -contains $pstnUsage} | Select-Object *,@{label="PstnUsage"; Expression= {$pstnUsage}}
            }
            $matchedVoiceRoutes = $voiceRoutes | Where-Object {$normalizedNumber -match $_.NumberPattern}
            if ($matchedVoiceRoutes) {
                $chosenPstnUsage = $matchedVoiceRoutes[0].PstnUsage
                $matchedPstnUsageVoiceRoutes = $matchedVoiceRoutes | Where-Object {$_.PstnUsage -eq $chosenPstnUsage} | Select-Object Name, NumberPattern, PstnUsage, OnlinePstnGatewayList, Priority
            } else {
                $matchedVoiceRoutes = $null
            }
        }
        catch {
            $Error[0]
        }
    }
    end {
        Write-Output "`n";Write-Output "LineUri assigned to $userDisplayName is [$($userReturned.LineUri)]"
        Write-Output "The following plans are assigned to $userDisplayName`:"
        $UserReturned.AssignedPlan | Select-Object Capability,CapabilityStatus | ft
        Write-Output "`r";Write-Output "Getting Effective Tenant Dial Plan for $userDisplayName..."
        Write-Output "Dial Plans assigned to $userDisplayName are: [$($assignedDialPlans -join ", ")]"
        if ($normalizedNumber) {
            Write-Output "Dialed number `'$DialedNumber`' translated to [$normalizedNumber] using the following rule:"
            $matchingRule | fl
        } else {
            Write-Output "No translation patterns matched";Write-Output "`r"
        }
        Write-Output "Getting assigned Online Voice Routing Policy for $userDisplayName..."
        Write-Output "Online Voice Routing Policy assigned to $userDisplayName is: [$UserOnlineVoiceRoutingPolicy]"
        if ($matchedVoiceRoutes) {
            Write-Output "First Matching PSTN Usage is [$chosenPstnUsage]"
            Write-Output "Found [$(($matchedPstnUsageVoiceRoutes).Count)] routes with matching pattern in PSTN Usage:"
            $matchedPstnUsageVoiceRoutes | ft
        } else {
            Write-Warning -Message "No route with matching pattern found, unable to route call using Direct Routing."
        }
    }
}

<#
Function TestRouting {
    param([Parameter(mandatory=$true)][String]$UserPrincipalName,[Parameter(mandatory=$true)][String]$DialedNumber)
    $VoiceRoutes = @()
    $MatchedVoiceRoutes = @()
    $UserReturned = Get-CsOnlineUser -Identity $UserPrincipalName -ErrorAction SilentlyContinue
    $AllVoiceRoutes = Get-CsOnlineVoiceRoute
    if ($UserReturned) {
        Write-Host "`nGetting Effective Tenant Dial Plan for $UserPrincipalName and translating number..."
        if ($UserReturned.TenantDialPlan) {
            Write-Host "Dial Plans assigned to $UserPrincipalName are: `'$($UserReturned.TenantDialPlan.Name + ", " + $UserReturned.DialPlan + " `(Usage Location`)")`'" -ForegroundColor Green
        } else {
            Write-Host "Dial Plans assigned to $UserPrincipalName are: $("`'Global, " + $UserReturned.DialPlan + " `(Usage Location`)`'")" -ForegroundColor Green
        }
        $NormalisedResult = Test-CsEffectiveTenantDialPlan -DialedNumber $DialedNumber -Identity $UserReturned.UserPrincipalName
            if ($NormalisedResult.TranslatedNumber) {
            Write-Host "`n$DialedNumber translated to $($NormalisedResult.TranslatedNumber)" -ForegroundColor Green
            Write-Host "`nUsing rule:`n$($NormalisedResult.MatchingRule -replace ";","`n")"
            $NormalisedNumber = $NormalisedResult.TranslatedNumber
        } else {
            Write-Host "`rNo translation patterns matched"
            $NormalisedNumber = $DialedNumber
        }
        Write-Host "`nGetting assigned Online Voice Routing Policy for $($UserReturned.UserPrincipalName)..."
        $UserOnlineVoiceRoutingPolicy = ($UserReturned).OnlineVoiceRoutingPolicy
        if ($UserOnlineVoiceRoutingPolicy) {
            Write-Host "`rOnline Voice Routing Policy assigned to $UserPrincipalName is: '$UserOnlineVoiceRoutingPolicy'" -ForegroundColor Green
            $PSTNUsages = (Get-CsOnlineVoiceRoutingPolicy -Identity $UserOnlineVoiceRoutingPolicy).OnlinePstnUsages
            foreach ($PSTNUsage in $PSTNUsages) {
                $VoiceRoutes += $AllVoiceRoutes | Where-Object {$_.OnlinePstnUsages -contains $PSTNUsage} | Select-Object *,@{label="PSTNUsage"; Expression= {$PSTNUsage}}
            }
            Write-Host "`nFinding the first PSTN Usage with a Voice Route that matches $NormalisedNumber..."
            $MatchedVoiceRoutes = $VoiceRoutes | Where-Object {$NormalisedNumber -match $_.NumberPattern}
            if ($MatchedVoiceRoutes) {
                $ChosenPSTNUsage = $MatchedVoiceRoutes[0].PSTNUsage
                Write-Host "`rFirst Matching PSTN Usage: '$ChosenPSTNUsage'"
                $MatchedVoiceRoutes = $MatchedVoiceRoutes | Where-Object {$_.PSTNUsage -eq $ChosenPSTNUsage}
                Write-Host "`rFound $(@($MatchedVoiceRoutes).Count) Voice Route(s) with matching pattern in PSTN Usage '$ChosenPSTNUsage', listing in priority order..." -ForegroundColor Green
                $MatchedVoiceRoutes | Select-Object Name, NumberPattern, PSTNUsage, OnlinePstnGatewayList, Priority | Format-Table
                Write-Host "LineUri assigned to $($UserReturned.DisplayName) is: " -NoNewline -ForegroundColor Green
                Write-Host "$($UserReturned.LineUri)"
                Write-Host "`nNote: Once a Voice Route that matches is found in a PSTN Usage, all other Voice Routes in other PSTN Usages will be ignored." -ForegroundColor Yellow
            } else { Write-Warning -Message "No Voice Route with matching pattern found, unable to route call using Direct Routing." }
        } else {
            Write-Host "`rOnline Voice Routing Policy assigned to $UserPrincipalName is: 'Global'" -ForegroundColor Green
            $PSTNUsages = (Get-CsOnlineVoiceRoutingPolicy -Identity Global).OnlinePstnUsages
            if ($PSTNUsages) {
                foreach ($PSTNUsage in $PSTNUsages) {
                    $VoiceRoutes += $AllVoiceRoutes | Where-Object {$_.OnlinePstnUsages -contains $PSTNUsage} | Select-Object *,@{label="PSTNUsage"; Expression= {$PSTNUsage}}
                }
                Write-Host "`nFinding the first PSTN Usage with a Voice Route that matches $NormalisedNumber..."
                $MatchedVoiceRoutes = $VoiceRoutes | Where-Object {$NormalisedNumber -match $_.NumberPattern}
                if ($MatchedVoiceRoutes) {
                    $ChosenPSTNUsage = $MatchedVoiceRoutes[0].PSTNUsage
                    Write-Host "`rFirst Matching PSTN Usage: '$ChosenPSTNUsage'"
                    $MatchedVoiceRoutes = $MatchedVoiceRoutes | Where-Object {$_.PSTNUsage -eq $ChosenPSTNUsage}
                    Write-Host "`rFound $(@($MatchedVoiceRoutes).Count) Voice Route(s) with matching pattern in PSTN Usage '$ChosenPSTNUsage', listing in priority order..." -ForegroundColor Green
                    $MatchedVoiceRoutes | Select-Object Name, NumberPattern, PSTNUsage, OnlinePstnGatewayList, Priority | Format-Table
                    Write-Host "LineUri assigned to $($UserReturned.DisplayName) is: " -NoNewline -ForegroundColor Green
                    Write-Host "$($UserReturned.LineUri)"
                    Write-Host "`nNote: Once a Voice Route that matches is found in a PSTN Usage, all other Voice Routes in other PSTN Usages will be ignored." -ForegroundColor Yellow
                } else { Write-Warning -Message "No Voice Route with matching pattern found, unable to route call using Direct Routing." }
            } else { Write-Warning -Message "No PSTN usages are assigned to the Global policy." }
        }
    } else { Write-Warning -Message "$UserPrincipalName not found on tenant." }
}
#>
