<#

.SYNOPSIS

    Export-TeamsGuests.ps1 - Displays a list and exports a CSV of Teams guests

.DESCRIPTION

    Author: csatswo

    This script will output a list of the Teams guests in the terminal and will save a CSV of the results.

.LINK

    Github: https://github.com/csatswo/Export-TeamsGuests.ps1

.EXAMPLE 

    .\Export-TeamsGuests.ps1 -Username admin@domain.onmicrosoft.com -Path C:\Temp\guests.csv    

        Displays a formatted table of Teams with guests and the guests of the Team.

        TeamDisplayName GuestName      GuestUser                                                     
        --------------- ---------      ---------                                                     
        Contoso         Tony Stark     tony.stark_domain.com#EXT#@domain.onmicrosoft.com
        Contoso         Bruce Banner   bruce.banner_domain.com#EXT#@domain.onmicrosoft.com              
        Test Team 1     csatswo        csatswo_domain.com#EXT#@domain.onmicrosoft.com

#>

# Script setup

Param(
    [Parameter(mandatory=$True)][String]$Username,
    [Parameter(mandatory=$True)][String]$Path
)

# Start script loops

$Teams = @()
$Teams = Get-Team
$CustomObject = @()

Foreach ($Team in $Teams) {
    
    $TeamId = @()
    $TeamId = $Team.GroupId
    
    $Guests = @()
    $Guests = Get-TeamUser -GroupId $TeamId -Role Guest

    Foreach ($Guest in $Guests) {
        
        $CustomProperties = @{
            GuestUserId = $Guest.UserId
            GuestUser = $Guest.User
            GuestName = $Guest.Name
            GuestRole = $Guest.Role
            TeamGroupId = $Team.GroupId
            TeamDisplayName = $Team.DisplayName
            TeamVisibility = $Team.Visibility
            TeamArchived = $Team.Archived
            TeamMailNickName = $Team.MailNickName
            TeamDescription = $Team.Description
            }

        $ObjectProperties = New-Object -TypeName PSObject -Property $CustomProperties
        $CustomObject += $ObjectProperties

        }

    }

Write-Host "`n`nThe following guests were found:" -ForegroundColor Cyan
Write-Output $CustomObject | Select-Object TeamDisplayName,GuestName,GuestUser | Sort-Object -Property TeamDisplayName | Format-Table

$CustomObject | Export-Csv -Path $Path -NoTypeInformation

Write-Host "Export saved to " -ForegroundColor Cyan -NoNewline
Write-Host $Path -ForegroundColor Yellow -NoNewline
Write-Host `n

<#
This section is experimental and is commented out intentionally.

function Get-TeamsGuests {
    Write-Output $CustomObject | Select-Object TeamDisplayName,TeamGroupId,GuestName,GuestUser | Sort-Object -Property TeamDisplayName
    }
#>
