# export_teams_guests.ps1
# Exports a CSV of all teams with guests and the complete membership of those teams
# Optionally, exports only when the guests are from a specific domain

# Specify an optional specific guest domain to look for
$domain = $null # Example: "gmail.com"

$tenant = "lab"
if (-not $tenant) { $tenant = ((Read-Host -Prompt "Enter the name of the Tenant...") -Replace '[\W]','').Trim() }
$allTeams = Get-Team -NumberOfThreads 4
$timeStamp = Get-Date -Format "yyyy-dd-MM-HHmmss"
$results  = [System.Collections.ArrayList]@()
$failures = [System.Collections.ArrayList]@()
$i = 0; foreach ($team in $allTeams) {
    $i++; $percentComplete = [int](($i / $allTeams.Count) * 100)
    Write-Progress -Activity "Processing Team: $($team.DisplayName)" -Status "$percentComplete% Complete:" -PercentComplete $percentComplete
    try {
        $members  = Get-TeamUser -GroupId $team.GroupId -ErrorAction Stop
        $guests = $members | Where-Object {$_.Role -eq "Guest" -and $_.User -like "*$domain#EXT#*"}
        if ($guests) {
            foreach ($member in $members) {
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
                [void]$results.Add($item)
            }
        }
    }
    catch {
        $item = [PSCustomObject]@{
            Team = $team.DisplayName
            MailNickName = $team.MailNickName
            GroupId = $team.GroupId
            Error = $Error[0].Exception
        }
        [void]$failures.Add($item)
        $item | Format-List
    }
}
if ($failures) { $failures | Export-Csv -Path "$PWD\teams_with_guests_FAILURES_$timeStamp.csv" -NoTypeInformation }
$results | Export-Csv -Path "$PWD\teams_with_guests_$timeStamp.csv" -NoTypeInformation
