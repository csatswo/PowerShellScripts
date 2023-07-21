<#
.SYNOPSIS

    Export-MsolGroupMembers.ps1 - Creates a CSV of groups and members

.DESCRIPTION

    Author: csatswo
    This script will output a list of the groups and members in the terminal and will save a CSV on the desktop.
    Assumes an active session with MSOnline (Connect-MsolService).

.PARAMETER Path

    The path for the exported CSV. For example: "C:\Temp\members.csv"

.PARAMETER Filter

    Filter string for group names. Use with asterisk for wildcard searches. For example: "*sales*" or "Project*"

.EXAMPLE

    .\Export-MsolGroupMembers.ps1 -Path C:\Temp\members.csv -Filter *sales*
    This will export all groups with 'sales' somewhere in the name

.EXAMPLE

    .\Export-MsolGroupMembers.ps1 -Path C:\Temp\members.csv -Filter Project*
    This will export all groups where the name starts with 'project'

.EXAMPLE

    .\Export-MsolGroupMembers.ps1 -Path C:\Temp\members.csv
    This will export all groups
#>

Param(
    [Parameter(mandatory=$true)][String]$Path,
    [Parameter(mandatory=$false)][String]$Filter
)

$results = @()

if ($Filter) {
    $groups = Get-MsolGroup -All | Where-Object {$_.DisplayName -like "$filter"}
} else {
    $groups = Get-MsolGroup -All
}

foreach ($group in $groups) {
    foreach ($member in (Get-MsolGroupMember -GroupObjectId $group.ObjectId)) {
        $customProperties = @{
            Group = $group.DisplayName
            GroupID = $group.ObjectId
            GroupType = $group.GroupType
            Member = $member.DisplayName
            MemberEmail = $member.EmailAddress
            MemberType = $member.GroupMemberType
        }
        $results += New-Object -TypeName PSObject -Property $customProperties
    }
}

$results | Sort-Object Group,MemberEmail | Select-Object Group,GroupType,Member,MemberEmail,MemberType | Format-Table -AutoSize

$results | Sort-Object Group,MemberEmail | Select-Object Group,GroupID,GroupType,Member,MemberEmail,MemberType | Export-Csv -Path $Path -NoTypeInformation
