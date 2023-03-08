<# 
.SYNOPSIS

    New-TeamGeneralChannelTaggedMessage
    Adds the account as an owner of the Team and posts a message in the 'General' channel.
    Created for the purpose of notifying members that the Team is being migrated and no changes should be made.

.DESCRIPTION

    Author: csatswo
    Adds the account as an owner of the Team and posts a message in the 'General' channel.
    Created for the purpose of notifying members that the Team is being migrated and no changes should be made.
    The 'Message' parameter is used to define a custom message.

.PARAMETER GroupId

    The group ID of the Team

.PARAMETER Message

    The body of the message to be posted in the channel.

.PARAMETER Importance

    OPTIONAL: If not used, the message will be posted with 'normal' importance.  Valid options are 'normal', 'high', and 'urgent'.

.EXAMPLE

    .\New-TeamGeneralChannelTaggedMessage -GroupID "01234567-89AB-CDEF-0123-456789ABCDEF"

.EXAMPLE

    .\New-TeamGeneralChannelTaggedMessage -GroupID "01234567-89AB-CDEF-0123-456789ABCDEF" -Message "Hello World" -Importance "High"

#>
#Requires -Modules Microsoft.Graph.Teams,Microsoft.Graph.Users
Param(
    [parameter(Mandatory=$true,ValueFromPipeline=$true)][ValidateScript({[guid]::TryParse($_,$([ref][guid]::Empty))})][string]$GroupId,
    [parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Message,
    [parameter(Mandatory=$false,ValueFromPipeline=$true)][ValidateScript({$_ -match "Normal|High|Urgent"})][string]$Importance
)
try {
    $scopes = @(
        "User.Read.All",
        "TeamMember.Read.All",
        "Group.ReadWrite.All",
        "ChannelMessage.Send"
    )
    $mgContext = Get-MgContext
    if ($mgContext) {
        if (-not ($mgContext.Scopes -contains $Scopes[0] -and $mgContext.Scopes -contains $Scopes[1] -and $mgContext.Scopes -contains $Scopes[2] -and $mgContext.Scopes -contains $Scopes[3])) {
            Write-Warning "Missing required MgContext scopes - connecting with all required scopes"
            Connect-MgGraph -Scopes $scopes | Out-Null
            Write-Warning "New permissions added - please try again in a few minutes"
            Break
        }
    }
    else {
        Connect-MgGraph -Scopes $scopes | Out-Null
        $mgContext = Get-MgContext
    }
    $mgUser = (Get-MgUser -UserId $mgContext.Account)
    $team = Get-MgTeam -TeamId $GroupId
    $generalChannel = Get-MgTeamChannel -TeamId $team.Id -Filter "DisplayName eq 'General'"
    $teamOwners = Get-MgTeamMember -TeamId $GroupId | Where-Object {$_.Roles -contains "owner"}
    if ($teamOwners.AdditionalProperties.userId -notcontains $mgUser.Id) {
        Write-Warning "$($mgUser.UserPrincipalName) is not an owner - adding as owner now"
        $bindingUri = "https://graph.microsoft.com/v1.0/users('$($mgUser.Id)')"
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
        $mgUserResults = Add-MgTeamMember -TeamId $team.Id -BodyParameter $memberParams
        Start-Sleep -Seconds 5 # Giving Teams a moment to replicate after adding owner
    }
    if (-not $Importance) {
        $Importance = "Normal"
    }
    if ($Message) {
        $content = "<div><div><at id=0>$($team.DisplayName)</at><br>$Message</div></div>"
    }
    else {
        $content = "<div><div><at id=0>$($team.DisplayName)</at></div></div>"
    }
    $messageParams = @{
        Importance = $Importance
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
} catch {
    $Error[0]
}
$results | Select-Object Id,CreatedDateTime,MessageType,WebUrl
