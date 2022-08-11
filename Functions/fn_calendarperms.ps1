Function CalendarPerms {
    [CmdletBinding()]Param(
        [string]$Identity
        )
    if ($Identity) {
        $mailboxes = Get-Mailbox -Identity $Identity
    } else {
        Write-Warning -Message "This will search all mailboxes. This can be extremely slow."
        $proceed = Read-Host -Prompt "Type `'Yes`' to proceed"
        if ($proceed -eq "Yes") {
            $mailboxes = Get-Mailbox
        } else { Break }
    }
    $calendarPermissions = @()
    foreach ($mailbox in $mailboxes) {
        $folder = $($mailbox.Alias)+":\calendar"
        $calendarPermissions += Get-MailboxFolderPermission -Identity $folder
    }
    $calendarPermissions | Sort-Object Identity | Select-Object Identity,FolderName,User,AccessRights
}
<#
    Write-Warning -Message "This will apply LimitedDetails access rights to the Default user for the selected account(s)."
    $proceed = Read-Host -Prompt "Type `'Yes`' to proceed"
    if ($proceed -eq "Yes") {
        foreach ($mailbox in $mailboxes) {
            $folder = $($mailbox.Alias)+":\calendar"
            Set-MailboxFolderPermission -Identity $folder -User Default -AccessRights LimitedDetails
        }
    } else { Break }
#>