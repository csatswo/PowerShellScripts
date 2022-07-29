Function TeamGuests {
    Param(
        [Parameter(mandatory=$false)][String]$GroupId,
        [Parameter(mandatory=$false)][String]$MailNickName,
        [Parameter(mandatory=$false)][String]$DisplayName
    )
    $teamsGuests = @()
    $teams = @()
    if ($GroupId) {
        $teams = Get-Team -GroupId $GroupId -WarningAction SilentlyContinue
    }
    if ($MailNickName) {
        $teams = Get-Team -MailNickName $MailNickName -WarningAction SilentlyContinue
    }
    if ($DisplayName) {
        $teams = Get-Team -DisplayName $DisplayName -WarningAction SilentlyContinue
    }
    if (-not ($teams)) {
        $teams = Get-Team -WarningAction SilentlyContinue
    }
    Foreach ($team in $teams) {
        $guests = Get-TeamUser -GroupId $team.GroupId -Role Guest
        Foreach ($guest in $guests) {
            $teamsGuests += [PSCustomObject]@{
                GuestUserId = $guest.UserId
                UserPrincipalName = $guest.User
                DisplayName = $guest.Name
                GuestRole = $guest.Role
                TeamGroupId = $team.GroupId
                TeamDisplayName = $team.DisplayName
                TeamVisibility = $team.Visibility
                TeamArchived = $team.Archived
                TeamMailNickName = $team.MailNickName
                TeamDescription = $team.Description
            }
        }
    }
    if ($teamsGuests) {
        Write-Host "`n`nThe following guests were found:" -ForegroundColor Cyan
        $teamsGuests | Sort-Object TeamDisplayName
    } else {
        Write-Host "`n`nNo guests were found" -ForegroundColor Cyan
    }
}
