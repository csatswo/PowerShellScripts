Function roomCalPerms {
    [CmdletBinding()]Param(
        [string]$prop,
        [string]$search
        )
    $teamsRooms = Get-Mailbox -Filter "($prop -like '*$search*')"
    $teamsRoomsPermissions = @()
    foreach ($teamsRoom in $teamsRooms) {
        $folder = $($teamsRoom.Alias)+":\calendar"
        $teamsRoomsPermissions += Get-MailboxFolderPermission -Identity $folder
    }
    $teamsRoomsPermissions | Sort-Object Identity | Select-Object Identity,FolderName,User,AccessRights
<#
    foreach ($teamsRoom in $teamsRooms) {
        $folder = $($teamsRoom.Alias)+":\calendar"
        Set-MailboxFolderPermission -Identity $folder -User Default -AccessRights LimitedDetails
    }
#>
}