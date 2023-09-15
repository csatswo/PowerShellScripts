# export_teams_guests.ps1
# Exports a CSV of all teams with guests and the complete membership of those teams
# Optionally, exports only when the guests are from a specific domain

# Specify an optional specific guest domain to look for
$domain = $null # Example: "gmail.com"

$allTeams = Get-Team -NumberOfThreads 4
$timeStamp = Get-Date -Format "yyyy-dd-MM-HHmmss"
$results  = [System.Collections.ArrayList]@()
$failures = [System.Collections.ArrayList]@()
$i = 0; foreach ($team in $allTeams) {
    $i++; $percentComplete = [int](($i / $allTeams.Count) * 100)
    Write-Progress -Activity "Processing Team: $($team.DisplayName)" -Status "$percentComplete% Complete:" -PercentComplete $percentComplete
    try {
        $members  = Get-TeamUser -GroupId $team.GroupId -ErrorAction Stop
        $guests = $members | ? {$_.Role -eq "Guest" -and $_.User -like "*$domain#EXT#*"}
        if ($guests) {
            foreach ($member in $members) {
                $item = [PSCustomObject]@{
                    Team = $team.DisplayName
                    MailNickName = $team.MailNickName
                    GroupId = $team.GroupId
                    Name = $member.Name
                    User = $member.User
                    UserId = $member.UserId
                    Role = $member.Role
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
        $item | fl
    }
}
if ($failures) { $failures | Export-Csv -Path "$PWD\teams_with_guests_FAILURES_$timeStamp.csv" -NoTypeInformation }
$results | Export-Csv -Path "$PWD\teams_with_guests_$timeStamp.csv" -NoTypeInformation
