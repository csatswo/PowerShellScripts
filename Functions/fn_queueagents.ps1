Function QueueAgents {
Param(
    [Parameter(mandatory=$false)][String]$Name,
    [Parameter(mandatory=$false)][String]$Path
)
$Queues = @()
if ($Name) {
$Queues = Get-CsCallQueue -WarningAction SilentlyContinue | Where-Object {$_.Name -like "$Name"}
} else {
$Queues = Get-CsCallQueue -WarningAction SilentlyContinue
}
$CallQueueUsers = @()
foreach ($Queue in $Queues) {
    $Users = @()
    $Groups = @()
    $Users = $Queue.Users
    $Groups = $Queue.DistributionLists
    foreach ($User in $Users) {
        $QueueUser = @()
        $QueueMsolUser = @()
        $QueueUser = Get-CsOnlineUser -Identity $User.Guid
        $QueueUserProperties = @{
            UserDisplayName = $QueueUser.DisplayName
            UserPrincipalName = $QueueUser.UserPrincipalName
            UserSipAddress = $QueueUser.SipAddress
            QueueAssignment = "Direct"
            GroupName = "N/A"
            CallQueue = $Queue.Name
            CallQueueId = $Queue.Identity
            ConferenceMode = $Queue.ConferenceMode
            }
        $CallQueueUsers += New-Object -TypeName PSObject -Property $QueueUserProperties
        }
    foreach ($Group in $Groups) {
        $QueueGroup = @()
        $QueueGroupMembers = @()
        $QueueGroup = Get-MsolGroup -ObjectId $Group.Guid
        $QueueGroupMembers = Get-MsolGroupMember -GroupObjectId $Group.Guid
        foreach ($QueueGroupMember in $QueueGroupMembers) {
            if((Get-MsolUser -ObjectId $QueueGroupMember.ObjectId).isLicensed -like $false) {
                Write-Host "`nWarning: " -ForegroundColor Yellow -NoNewline
                Write-Host $QueueGroupMember.DisplayName -ForegroundColor White -NoNewline
                Write-Host " is not licensed" -ForegroundColor Yellow -NoNewline
                Write-Host `n
                $Member = @()
                $MsolMember = @()
                $MsolMember = Get-MsolUser -ObjectId $QueueGroupMember.ObjectId
                $MemberProperties = @{
                    UserDisplayName = $MsolMember.DisplayName
                    UserPrincipalName = $MsolMember.UserPrincipalName
                    UserSipAddress = "Not Licensed"
                    QueueAssignment = $QueueGroup.GroupType
                    GroupName = $QueueGroup.DisplayName
                    CallQueue = $Queue.Name
                    CallQueueId = $Queue.Identity
                    ConferenceMode = $Queue.ConferenceMode
                    }
                $CallQueueUsers += New-Object -TypeName PSObject -Property $MemberProperties
            } else {
                $Member = @()
                $MsolMember = @()
                $Member = Get-CsOnlineUser -Identity $QueueGroupMember.ObjectId
                if(($Member).SipAddress -eq $null) {
                    $MsolMember = Get-MsolUser -ObjectId $QueueGroupMember.ObjectId
                    $MemberProperties = @{
                        UserDisplayName = $MsolMember.DisplayName
                        UserPrincipalName = $MsolMember.UserPrincipalName
                        UserSipAddress = "Not Teams Enabled"
                        QueueAssignment = $QueueGroup.GroupType
                        GroupName = $QueueGroup.DisplayName
                        CallQueue = $Queue.Name
                        CallQueueId = $Queue.Identity
                        ConferenceMode = $Queue.ConferenceMode
                        }
                    $CallQueueUsers += New-Object -TypeName PSObject -Property $MemberProperties
                    } else {
                    $MemberProperties = @{
                        UserDisplayName = $Member.DisplayName
                        UserPrincipalName = $Member.UserPrincipalName
                        UserSipAddress = $Member.SipAddress
                        QueueAssignment = $QueueGroup.GroupType
                        GroupName = $QueueGroup.DisplayName
                        CallQueue = $Queue.Name
                        CallQueueId = $Queue.Identity
                        ConferenceMode = $Queue.ConferenceMode
                        }
                    $CallQueueUsers += New-Object -TypeName PSObject -Property $MemberProperties
                    }
                }
            }
        }
    }
Write-Output $CallQueueUsers | Select-Object CallQueue,QueueAssignment,GroupName,UserDisplayName,UserSipAddress | Sort-Object -Property @{Expression="CallQueue"},@{Expression="GroupName"},@{Expression="UserDisplayName"} | Format-Table
if ($Path) {
$CustomObject | Select-Object CallQueue,CallQueueId,ConferenceMode,QueueAssignment,GroupName,UserDisplayName,UserPrincipalName,UserSipAddress | Sort-Object -Property @{Expression="CallQueue"},@{Expression="GroupName"},@{Expression="UserDisplayName"} | Export-Csv -Path $Path -NoTypeInformation
Write-Host "Export saved to " -ForegroundColor Cyan -NoNewline
Write-Host $Path -ForegroundColor Yellow -NoNewline
Write-Host `n
}}