<# 
.SYNOPSIS

    Convert-SlackExportToExcel
    Extracts Channels and Users from Slack export ZIP file. Requires the 'ImportExcel' module.

.DESCRIPTION

    Author: csatswo
    Extracts the 'channels.json', 'groups.json', and 'users.json' files from a Slack export.
    Parses the extracted json files and exports the data into XLSX in same directory as ZIP.
    Requires the 'ImportExcel' module (Install-Module ImportExcel).

.PARAMETER Path

    The path of the Slack export ZIP file.

.EXAMPLE

    .\Convert-SlackExportToExcel -Path C:\Temp\SlackExport.zip
#>

Param(
    [Parameter(mandatory=$true)][String]$Path
)

if (Test-Path $path) {

    # Check for "ImportExcel" module
    if (Get-Module -ListAvailable -Name ImportExcel) {
        Import-Module ImportExcel
    } else {
        Write-Warning "ImportExcel module is not installed. Install using `"Install-Module`""
        break
    }

    # Get the Slack Export ZIP file
    $pathZIP = Get-Item $path

    # Extract the Channels, Groups, and Users json files to same folder as the ZIP
    Write-Host "Extracting json files from zip..."
    Add-Type -AssemblyName "System.IO.Compression.FileSystem"
    $zip = [IO.Compression.ZipFile]::OpenRead(($pathZIP).FullName)
    $zip.Entries | Where-Object {$_.Name -eq "channels.json" -or $_.Name -eq "groups.json" -or $_.Name -eq "users.json"} | ForEach-Object { 
        $FileName = $_.Name
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, "$($pathZIP.Directory)\$FileName", $true)
    }
    $zip.Dispose()

    # Import the extracted json files
    $channelsJson = Get-Content "$($pathZIP.Directory)\channels.json" | ConvertFrom-Json
    $groupsJson = Get-Content "$($pathZIP.Directory)\groups.json" | ConvertFrom-Json
    $usersJson = Get-Content "$($pathZIP.Directory)\users.json" | ConvertFrom-Json

    $usersHashTable = $usersJson | Group-Object -AsHashTable -Property ID
    $channelsHashTable = $channelsJson | Group-Object -AsHashTable -Property ID
    $groupsHashTable = $groupsJson | Group-Object -AsHashTable -Property ID
    
    $channels = @()
    $users = @()

    # Loop to process the users
    Write-Host "Parsing users.json file..."
    foreach ($userID in $usersHashTable.Keys) {
        
        # Test if values exist, set to $null if not exist
        try { $realNameFromJson = $usersHashTable[$userID].profile.real_name } catch { $realNameFromJson = $null }
        try { $displayNameFromJson = $usersHashTable[$userID].profile.display_name } catch { $displayNameFromJson = $null }
        try { $firstNameFromJson = $usersHashTable[$userID].profile.first_name } catch { $firstNameFromJson = $null }
        try { $lastNameFromJson = $usersHashTable[$userID].profile.last_name } catch { $lastNameFromJson = $null }
        try { $emailFromJson = $usersHashTable[$userID].profile.email } catch { $emailFromJson = $null }
        try { $adminFromJson = $usersHashTable[$userID].is_admin } catch { $adminFromJson = $null }
        try { $ownerFromJson = $usersHashTable[$userID].is_owner } catch { $ownerFromJson = $null }
        try { $primaryOwnerFromJson = $usersHashTable[$userID].is_primary_owner } catch { $primaryOwnerFromJson = $null }
        try { $restrictedFromJson = $usersHashTable[$userID].is_restricted } catch { $restrictedFromJson = $null }
        try { $ultraRestrictedFromJson = $usersHashTable[$userID].is_ultra_restricted } catch { $ultraRestrictedFromJson = $null }
        try { $botFromJson = $usersHashTable[$userID].is_bot } catch { $botFromJson = $null }
        try { $appUserFromJson = $usersHashTable[$userID].is_app_user } catch { $appUserFromJson = $null }
        try { $deletedFromJson = $usersHashTable[$userID].deleted } catch { $deletedFromJson = $null }

        $customProperties = @{
            ID = $usersHashTable[$userID].id
            RealName = $realNameFromJson
            DisplayName = $displayNameFromJson
            FirstName = $firstNameFromJson
            LastName = $lastNameFromJson
            Email = $emailFromJson
            Admin = $adminFromJson
            Owner = $ownerFromJson
            PrimaryOwner = $primaryOwnerFromJson
            Restricted = $restrictedFromJson
            UltraRestricted = $ultraRestrictedFromJson
            Bot = $botFromJson
            AppUser = $appUserFromJson
            Deleted = $deletedFromJson
        }
        $users += New-Object -TypeName PSObject -Property $customProperties

    }

    # Loop to process the private channels
    Write-Host "Parsing groups.json file (hash table)..."
    foreach ($groupID in $groupsHashTable.Keys) {

        try {

            # Test if channel has members
            $groupsHashTable[$groupID].members | Out-Null
            # Test if 'created' time stamp exists, set to $null if not exist
            try { $created = Get-Date ([System.DateTimeOffset]::FromUnixTimeSeconds($channelsHashTable[$channelID].created).ToString()) -UFormat %Y-%m-%d } catch { $created = $null }

            foreach ($member in $groupsHashTable[$groupID].members) {

                # Try to find a match for the member IDs, set to $null if no match
                if ($usersHashTable[$member]) {        
                    try { $realNameFromJson = $usersHashTable[$member].profile.real_name } catch { $realNameFromJson = $null }
                    try { $emailFromJson = $usersHashTable[$member].profile.email } catch { $emailFromJson = $null }
                } else {
                    $realNameFromJson = $null
                    $emailFromJson = $null
                }

                # Try to find a match for the creator IDs, set to $null if no match
                if ($usersHashTable[$groupsHashTable[$groupID].creator]) {
                    try { $creatorRealNameFromJson = $usersHashTable[$groupsHashTable[$groupID].creator].profile.real_name } catch { $creatorRealNameFromJson = $null }
                    try { $creatorEmailFromJson = $usersHashTable[$groupsHashTable[$groupID].creator].profile.email } catch { $creatorEmailFromJson = $null }
                } else {
                    $creatorRealNameFromJson = $null
                    $creatorEmailFromJson = $null
                }

                $customProperties = @{
                    Channel = $groupsHashTable[$groupID].name
                    ChannelID = $groupsHashTable[$groupID].id
                    Creator = $groupsHashTable[$groupID].creator
                    CreatorName = $creatorRealNameFromJson
                    CreatorEmail = $creatorEmailFromJson
                    Created = $created
                    Visibility = "Private"
                    Archived = $groupsHashTable[$groupID].is_archived
                    Member = $member
                    MemberName = $realNameFromJson
                    MemberEmail = $emailFromJson
                }
                $channels += New-Object -TypeName PSObject -Property $customProperties

            }

        } catch {

            # Test if 'created' time stamp exists, set to $null if not exist
            try { $created = Get-Date ([System.DateTimeOffset]::FromUnixTimeSeconds($channelsHashTable[$channelID].created).ToString()) -UFormat %Y-%m-%d } catch { $created = $null }

            # Try to find a match for the creator IDs, set to $null if no match
            if ($usersHashTable[$groupsHashTable[$groupID].creator]) {
                try { $creatorRealNameFromJson = $usersHashTable[$groupsHashTable[$groupID].creator].profile.real_name } catch { $creatorRealNameFromJson = $null }
                try { $creatorEmailFromJson = $usersHashTable[$groupsHashTable[$groupID].creator].profile.email } catch { $creatorEmailFromJson = $null }
            } else {
                $creatorRealNameFromJson = $null
                $creatorEmailFromJson = $null
            }

            $customProperties = @{
                Channel = $groupsHashTable[$groupID].name
                ChannelID = $groupsHashTable[$groupID].id
                Creator = $groupsHashTable[$groupID].creator
                CreatorName = $creatorRealNameFromJson
                CreatorEmail = $creatorEmailFromJson
                Created = $created
                Visibility = "Private"
                Archived = $groupsHashTable[$groupID].is_archived
                Member = $null
                MemberName = $realNameFromJson
                MemberEmail = $emailFromJson
            }

            $channels += New-Object -TypeName PSObject -Property $customProperties

        }

    }

    # Loop to process the public channels
    Write-Host "Parsing channels.json file (hash table)..."
    foreach ($channelID in $channelsHashTable.Keys) {

        try {

            # Test if channel has members
            $channelsHashTable[$channelID].members | Out-Null
            # Test if 'created' time stamp exists, set to $null if not exist
            try { $created = Get-Date ([System.DateTimeOffset]::FromUnixTimeSeconds($channelsHashTable[$channelID].created).ToString()) -UFormat %Y-%m-%d } catch { $created = $null }

            foreach ($member in $channelsHashTable[$channelID].members) {

                # Try to find a match for the member IDs, set to $null if no match
                if ($usersHashTable[$member]) {        
                    try { $realNameFromJson = $usersHashTable[$member].profile.real_name } catch { $realNameFromJson = $null }
                    try { $emailFromJson = $usersHashTable[$member].profile.email } catch { $emailFromJson = $null }
                } else {
                    $realNameFromJson = $null
                    $emailFromJson = $null
                }

                # Try to find a match for the creator IDs, set to $null if no match
                if ($usersHashTable[$channelsHashTable[$channelID].creator]) {
                    try { $creatorRealNameFromJson = $usersHashTable[$channelsHashTable[$channelID].creator].profile.real_name } catch { $creatorRealNameFromJson = $null }
                    try { $creatorEmailFromJson = $usersHashTable[$channelsHashTable[$channelID].creator].profile.email } catch { $creatorEmailFromJson = $null }
                } else {
                    $creatorRealNameFromJson = $null
                    $creatorEmailFromJson = $null
                }

                $customProperties = @{
                    Channel = $channelsHashTable[$channelID].name
                    ChannelID = $channelsHashTable[$channelID].id
                    Creator = $channelsHashTable[$channelID].creator
                    CreatorName = $creatorRealNameFromJson
                    CreatorEmail = $creatorEmailFromJson
                    Created = $created
                    Visibility = "Private"
                    Archived = $channelsHashTable[$channelID].is_archived
                    Member = $member
                    MemberName = $realNameFromJson
                    MemberEmail = $emailFromJson
                }
                $channels += New-Object -TypeName PSObject -Property $customProperties

            }

        } catch {

            # Test if 'created' time stamp exists, set to $null if not exist
            try { $created = Get-Date ([System.DateTimeOffset]::FromUnixTimeSeconds($channelsHashTable[$channelID].created).ToString()) -UFormat %Y-%m-%d } catch { $created = $null }

            # Try to find a match for the creator IDs, set to $null if no match
            if ($usersHashTable[$channelsHashTable[$channelID].creator]) {
                try { $creatorRealNameFromJson = $usersHashTable[$channelsHashTable[$channelID].creator].profile.real_name } catch { $creatorRealNameFromJson = $null }
                try { $creatorEmailFromJson = $usersHashTable[$channelsHashTable[$channelID].creator].profile.email } catch { $creatorEmailFromJson = $null }
            } else {
                $creatorRealNameFromJson = $null
                $creatorEmailFromJson = $null
            }

            $customProperties = @{
                Channel = $channelsHashTable[$channelID].name
                ChannelID = $channelsHashTable[$channelID].id
                Creator = $channelsHashTable[$channelID].creator
                CreatorName = $creatorRealNameFromJson
                CreatorEmail = $creatorEmailFromJson
                Created = $created
                Visibility = "Private"
                Archived = $channelsHashTable[$channelID].is_archived
                Member = $null
                MemberName = $realNameFromJson
                MemberEmail = $emailFromJson
            }

            $channels += New-Object -TypeName PSObject -Property $customProperties

        }

    }

# Export results to same folder as the ZIP
Write-Host "Saving results..."
$outputFile = "$($pathZIP.Directory)\Slack_Channels_and_Users_$(Get-Date -UFormat '%Y-%m-%d').xlsx"
$channels | Sort-Object Channel,Member | Select-Object Channel,ChannelID,Creator,CreatorName,CreatorEmail,Created,Visibility,Archived,Member,MemberName,MemberEmail | Export-Excel -WorksheetName "Channels" -Path $outputFile
$users | Sort-Object Email | Select-Object RealName,DisplayName,FirstName,LastName,Email,ID,Admin,Owner,PrimaryOwner,Restricted,UltraRestricted,Bot,AppUser,Deleted | Export-Excel -WorksheetName "Users" -Path $outputFile
Write-Host "Done! Results saved to $outputFile"

} else {

    Write-Warning "Path to Slack Export is invalid"

}
