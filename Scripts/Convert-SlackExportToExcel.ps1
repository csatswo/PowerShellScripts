<# 
 .Synopsis
  Extracts Channels and Users from Slack export ZIP file. Requires the 'ImportExcel' module.

 .Description
  Extracts the 'channels.json', 'groups.json', and 'users.json' files from a Slack export.
  Parses the extracted json files and exports the data into XLSX in same directory as ZIP.
  Requires the 'ImportExcel' module (Install-Module ImportExcel).

 .Parameter Path
  The path the Slack export ZIP file.

 .Example
   Convert-SlackExportToExcel -Path C:\Temp\SlackExport.zip
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
    
    $channels = @()
    $users = @()

    # Loop to process the public channels
    Write-Host "Parsing channels.json file..."
    foreach ($channel in $channelsJson) {
        foreach ($member in $channel.members) {
            $customProperties = @{
                Channel = $channel.name
                ChannelID = $channel.id
                Member = $member
                Visibility = "Public"
                Archived = $channel.is_archived
            }
            $channels += New-Object -TypeName PSObject -Property $customProperties
        }
    }

    # Loop to process the private channels
    Write-Host "Parsing groups.json file..."
    foreach ($channel in $groupsJSON) {
        foreach ($member in $channel.members) {
            $customProperties = @{
                Channel = $channel.name
                ChannelID = $channel.id
                Member = $member
                Visibility = "Private"
                Archived = $channel.is_archived
            }
            $channels += New-Object -TypeName PSObject -Property $customProperties
        }
    }

    # Loop to process the users
    Write-Host "Parsing users.json file..."
    foreach ($user in $usersJson) {
        $customProperties = @{
            RealName = $user.profile.real_name
            DisplayName = $user.profile.display_name
            FirstName = $user.profile.first_name
            LastName = $user.profile.last_name
            Email = $user.profile.email
            ID = $user.id
            Admin = $user.is_admin
            Owner = $user.is_owner
            PrimaryOwner = $user.is_primary_owner
            Restricted = $user.is_restricted
            UltraRestricted = $user.is_ultra_restricted
            Bot = $user.is_bot
            AppUser = $user.is_app_user
            Deleted = $user.deleted
        }
        $users += New-Object -TypeName PSObject -Property $customProperties
    }

# Export results to same folder as the ZIP
$outputFile = "$($pathZIP.Directory)\Slack_Channels_and_Users_$(Get-Date -UFormat '%Y-%m-%d').xlsx"
$channels | Sort-Object Channel,Member | Select-Object Channel,ChannelID,Member,Visibility,Archived | Export-Excel -WorksheetName "Channels" -Path $outputFile
$users | Sort-Object Email | Select-Object RealName,DisplayName,FirstName,LastName,Email,ID,Admin,Owner,PrimaryOwner,Restricted,UltraRestricted,Bot,AppUser,Deleted | Export-Excel -WorksheetName "Users" -Path $outputFile
Write-Host "Done! Results saved to $outputFile"

} else {

    Write-Warning "Path to Slack Export is invalid"

}
