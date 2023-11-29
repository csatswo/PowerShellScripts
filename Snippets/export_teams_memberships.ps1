# export_teams_memberships.ps1
# Exports a CSV of all teams and their complete memberships

$tenant = "lab"
if (-not $tenant) { $tenant = ((Read-Host -Prompt "Enter the name of the Tenant...") -Replace '[\W]','').Trim() }
$allTeams = Get-Team -NumberOfThreads 2
$timeStamp = Get-Date -Format "yyyy-dd-MM-HHmmss"
$teamMembershipReport = [System.Collections.ArrayList]@()
$i = 0; foreach ($team in $allTeams) {
    Clear-Host; $i++; $percentComplete = [int](($i / $allTeams.Count) * 100)
    Write-Progress -Activity "Processing Team: $($team.MailNickName)" -Status "$percentComplete% Complete:" -PercentComplete $percentComplete
    $teamMembership = Get-TeamUser -GroupId $team.GroupId
    foreach ($member in $teamMembership) {
        $item = [PSCustomObject]@{
            GroupId                           = $team.GroupId
            InternalId                        = $team.InternalId
            DisplayName                       = $team.DisplayName
            Description                       = $team.Description
            Visibility                        = $team.Visibility
            MailNickName                      = $team.MailNickName
            Classification                    = $team.Classification
            Archived                          = $team.Archived
            AllowGiphy                        = $team.AllowGiphy
            GiphyContentRating                = $team.GiphyContentRating
            AllowStickersAndMemes             = $team.AllowStickersAndMemes
            AllowCustomMemes                  = $team.AllowCustomMemes
            AllowGuestCreateUpdateChannels    = $team.AllowGuestCreateUpdateChannels
            AllowGuestDeleteChannels          = $team.AllowGuestDeleteChannels
            AllowCreateUpdateChannels         = $team.AllowCreateUpdateChannels
            AllowCreatePrivateChannels        = $team.AllowCreatePrivateChannels
            AllowDeleteChannels               = $team.AllowDeleteChannels
            AllowAddRemoveApps                = $team.AllowAddRemoveApps
            AllowCreateUpdateRemoveTabs       = $team.AllowCreateUpdateRemoveTabs
            AllowCreateUpdateRemoveConnectors = $team.AllowCreateUpdateRemoveConnectors
            AllowUserEditMessages             = $team.AllowUserEditMessages
            AllowUserDeleteMessages           = $team.AllowUserDeleteMessages
            AllowOwnerDeleteMessages          = $team.AllowOwnerDeleteMessages
            AllowTeamMentions                 = $team.AllowTeamMentions
            AllowChannelMentions              = $team.AllowChannelMentions
            ShowInTeamsSearchAndSuggestions   = $team.ShowInTeamsSearchAndSuggestions
            UserId                            = $member.UserId
            User                              = $member.User
            Name                              = $member.Name
            Role                              = $member.Role
        }
        [void]$teamMembershipReport.Add($item)
    }
    Clear-Host
}
$teamMembershipReport | Export-Csv -Path "$PWD\team_memberships_$timeStamp.csv" -NoTypeInformation
