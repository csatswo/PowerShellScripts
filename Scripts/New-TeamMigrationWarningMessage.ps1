<# 
.SYNOPSIS

    New-TeamMigrationWarningMessage
    Adds the account as an owner of the Team and posts an urgent message in the 'General' channel of a Team.
    Created for the purpose of notifying members that the Team is being migrated and no changes should be made.

.DESCRIPTION

    Author: csatswo
    Adds the account as an owner of the Team and posts an urgent message in the 'General' channel of a Team.
    Created for the purpose of notifying members that the Team is being migrated and no changes should be made.
    The optional 'MessageOverride' parameter can be used to define a custom message, otherwise a generic warning text is used.

.PARAMETER GroupId

    The group ID of the Team

.PARAMETER MigrationAccount

    The UserPrincipalName of the migration service account. This should also be the account used with 'Connect-MgGraph'.

.PARAMETER Urgent

    OPTIONAL: If included, the message will be marked as urgent.

.PARAMETER MessageOverride

    OPTIONAL: For defining a custom message. If not used, the following message is used:
    "This team is now being migrated. Please do not make any changes or posts in this team. Please do not reply to this post. Thank you!"

.EXAMPLE

    .\New-TeamMigrationWarningMessage -GroupID "01234567-89AB-CDEF-0123-456789ABCDEF" -MigrationAccount "MigrationWiz@example.com"

.EXAMPLE

    .\New-TeamMigrationWarningMessage -GroupID "01234567-89AB-CDEF-0123-456789ABCDEF" -MigrationAccount "MigrationWiz@example.com" -MessageOverride "Hello World"

#>
#Requires -Modules Microsoft.Graph.Teams,Microsoft.Graph.Users
Param(
    [parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$GroupId,
    [parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$MigrationAccount,
    [parameter(Mandatory=$false,ValueFromPipeline=$true)][switch]$Urgent,
    [parameter(Mandatory=$false,ValueFromPipeline=$true)][string]$MessageOverride
)
try {
    if ((Get-MgContext).Account -eq $MigrationAccount) {
        $migrationMgUser = (Get-MgUser -UserId $MigrationAccount)
        $migrationMgUser
        $team = Get-MgTeam -TeamId $GroupId
        $generalChannel = Get-MgTeamChannel -TeamId $team.Id -Filter "DisplayName eq 'General'"
        $teamOwners = Get-MgTeamMember -TeamId $GroupId | ? {$_.Roles -contains "owner"}
        if ($teamOwners.AdditionalProperties.userId -notcontains $migrationMgUser.Id) {
            Write-Warning "$($migrationMgUser.UserPrincipalName) is not an owner - adding as owner now"
            $bindingUri = "https://graph.microsoft.com/v1.0/users('$($migrationMgUser.Id)')"
            $memberParams = @{
            	Values = @(
            		@{
            			"@odata.type" = "microsoft.graph.aadUserConversationMember"
            			Roles = @(
            				"owner"
            			)
            			"User@odata.bind" = $bindingUri
            		}
            	)
            }
            $migrationMgUserResults = Add-MgTeamMember -TeamId $team.Id -BodyParameter $memberParams
            Start-Sleep -Seconds 5 # Giving Teams a moment to replicate after adding owner
        }
        if ($MessageOverride) {
            $content = "<div><div><at id=0>$($team.DisplayName)</at> - $MessageOverride</div></div>"
        }
        else {
            $MessageOverride = "This team is now being migrated. Please do not make any changes or posts in this team. Please do not reply to this post. Thank you!"
            $content = "<div><div><at id=0>$($team.DisplayName)</at> - $MessageOverride</div></div>"
        }
        if ($Urgent) {
            $importance = "urgent"
        }
        else {
            $importance = "normal"
        }
        $messageParams = @{
            Importance = $importance
            Body = @{
                ContentType = "html"
                Content = $content
            }
            Mentions = @(
                @{
                    Id = 0
                    MentionText = $team.DisplayName
                    Mentioned = @{
                        Conversation = @{
                            Id = $team.Id
                            DisplayName = $team.DisplayName
                            ConversationIdentityType = "team"
                        }
                    }
                }
            )
        }
        $results = New-MgTeamChannelMessage -TeamId $team.Id -ChannelId $generalChannel.Id -BodyParameter $messageParams
    }
    else {
        Write-Warning -Message "Not connected. Use `'Connect-MgGraph`' with $MigrationAccount"
    }
} catch {
    $Error[0]
}
$results | Select-Object Id,CreatedDateTime,MessageType,WebUrl
