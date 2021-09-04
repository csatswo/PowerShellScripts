Function TeamsGuests {
Param(
    [Parameter(mandatory=$false)][String]$Name,
    [Parameter(mandatory=$false)][String]$Path
)
$teamsGuests = @()
$teams = @()
if ($Name) {
    $teams = Get-Team -WarningAction SilentlyContinue | Where-Object {$_.DisplayName -like "$Name"}
    Foreach ($team in $teams) {
        $guests = Get-TeamUser -GroupId $team.GroupId -Role Guest
        Foreach ($guest in $guests) {
            $customProperties = @{
                GuestUserId = $guest.UserId
                GuestUser = $guest.User
                GuestName = $guest.Name
                GuestRole = $guest.Role
                TeamGroupId = $team.GroupId
                TeamDisplayName = $team.DisplayName
                TeamVisibility = $team.Visibility
                TeamArchived = $team.Archived
                TeamMailNickName = $team.MailNickName
                TeamDescription = $team.Description
                }
            $teamsGuests += New-Object -TypeName PSObject -Property $customProperties
        }
    }
} else {
    $teams = Get-Team -WarningAction SilentlyContinue
    Foreach ($team in $teams) {
        $guests = Get-TeamUser -GroupId $team.GroupId -Role Guest
        Foreach ($guest in $guests) {
            $customProperties = @{
                GuestUserId = $guest.UserId
                GuestUser = $guest.User
                GuestName = $guest.Name
                GuestRole = $guest.Role
                TeamGroupId = $team.GroupId
                TeamDisplayName = $team.DisplayName
                TeamVisibility = $team.Visibility
                TeamArchived = $team.Archived
                TeamMailNickName = $team.MailNickName
                TeamDescription = $team.Description
                }
            $teamsGuests += New-Object -TypeName PSObject -Property $customProperties
        }
    }
}
if ($teamsGuests) {
    Write-Host "`n`nThe following guests were found:" -ForegroundColor Cyan
    Write-Output $teamsGuests | Select-Object TeamDisplayName,GuestName,GuestUser | Sort-Object -Property TeamDisplayName | Format-Table
} else {
    Write-Host "`n`nNo guests were found" -ForegroundColor Cyan
}
if ($Path) {
    $teamsGuests | Export-Csv -Path $Path -NoTypeInformation
}}
