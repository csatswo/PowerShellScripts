Function TeamGuests {
    Param(
        [Parameter(mandatory=$false)][String]$GroupId,
        [Parameter(mandatory=$false)][String]$MailNickName,
        [Parameter(mandatory=$false)][String]$DisplayName
    )
    $teamsGuests = @()
    $teams = @()
    if ($GroupId) { $teams = @(Get-Team -GroupId $GroupId -WarningAction SilentlyContinue) }
    if ($MailNickName) { $teams = @(Get-Team -MailNickName $MailNickName -WarningAction SilentlyContinue) }
    if ($DisplayName) { $teams = @(Get-Team -DisplayName $DisplayName -WarningAction SilentlyContinue) }
    if (-not ($teams)) {
        Write-Warning -Message "This will run for every team and can be extremely slow."
        $proceed = Read-Host -Prompt "Type `'Yes`' to proceed"
        if ($proceed -eq "Yes") {
            $teams = @(Get-Team -WarningAction SilentlyContinue)
        } else { Break }
    }
    foreach ($team in $teams) {
        $guests = @(Get-TeamUser -GroupId $team.GroupId -Role Guest)
        foreach ($guest in $guests) {
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
        Write-Output "`n`nThe following guests were found:"
        $teamsGuests | Sort-Object TeamDisplayName
    } else {
        Write-Output "`nNo guests were found"
    }
}
