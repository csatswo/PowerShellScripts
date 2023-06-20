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
        $NormalisedResult = Test-CsEffectiveTenantDialPlan -DialedNumber $DialedNumber -Identity $User
            if ($NormalisedResult.TranslatedNumber) {
            Write-Host "`n$DialedNumber translated to $($NormalisedResult.TranslatedNumber)" -ForegroundColor Green
            Write-Host "`nUsing rule:`n$($NormalisedResult.MatchingRule -replace ";","`n")"
            $NormalisedNumber = $NormalisedResult.TranslatedNumber
        } else {
            Write-Host "`rNo translation patterns matched"
            $NormalisedNumber = $DialedNumber
        }
        Write-Host "`nGetting assigned Online Voice Routing Policy for $User..."
        $UserOnlineVoiceRoutingPolicy = ($UserReturned).OnlineVoiceRoutingPolicy
        if ($UserOnlineVoiceRoutingPolicy.Name) {
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