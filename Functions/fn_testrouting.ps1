Function TestRouting {
param([Parameter(mandatory=$true)][String]$User,[Parameter(mandatory=$true)][String]$DialedNumber)
$VoiceRoutes = @()
$MatchedVoiceRoutes = @()
$UserReturned = Get-CsOnlineUser -Identity $User -ErrorAction SilentlyContinue
if ($UserReturned) {
    Write-Host "`nGetting Effective Tenant Dial Plan for $User and translating number..."
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
    if ($UserOnlineVoiceRoutingPolicy) {
        Write-Host "`rOnline Voice Routing Policy assigned to $user is: '$UserOnlineVoiceRoutingPolicy'" -ForegroundColor Green
        $PSTNUsages = (Get-CsOnlineVoiceRoutingPolicy -Identity Global).OnlinePstnUsages #($UserOnlineVoiceRoutingPolicy).Name).OnlinePstnUsages
        foreach ($PSTNUsage in $PSTNUsages) {
            $VoiceRoutes += Get-CsOnlineVoiceRoute | Where-Object {$_.OnlinePstnUsages -contains $PSTNUsage} | Select-Object *,@{label="PSTNUsage"; Expression= {$PSTNUsage}}
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
        Write-Host "`rOnline Voice Routing Policy assigned to $user is: 'Global'" -ForegroundColor Green
        $PSTNUsages = (Get-CsOnlineVoiceRoutingPolicy -Identity Global).OnlinePstnUsages
        foreach ($PSTNUsage in $PSTNUsages) {
            $VoiceRoutes += Get-CsOnlineVoiceRoute | Where-Object {$_.OnlinePstnUsages -contains $PSTNUsage} | Select-Object *,@{label="PSTNUsage"; Expression= {$PSTNUsage}}
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
    }
} else { Write-Warning -Message "$user not found on tenant." }
}