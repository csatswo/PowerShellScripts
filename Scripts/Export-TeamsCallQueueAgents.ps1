<#

.SYNOPSIS
 
    Export-TeamsCallQueueAgents.ps1
    This script will display all Teams Call Queue agents and group members.
 
.DESCRIPTION
    
    Author: csatswo
    This script outputs to the terminal a table of all Teams Call Queue agents.  The table will show agents directly assigned to a queue as well as agents that are assigned via group membership.
    
.LINK

    https://github.com/csatswo/Export-TeamsCallQueueAgents.ps1
 
.EXAMPLE 
    
    .\Export-TeamsCallQueueAgents.ps1 -Path C:\Temp\Agents.csv

.EXAMPLE 
    
    .\Export-TeamsCallQueueAgents.ps1 -Path C:\Temp\Agents.csv -OverrideAdminDomain domain.onmicrosoft.com
    If using the 'SkypeOnlineConnector' module, the OverrideAdminDomain can be used.

#>

Param(
    [Parameter(mandatory=$true)][String]$Path,
    [Parameter(mandatory=$false)][string]$OverrideAdminDomain
)

Write-Host "`nChecking if required modules are installed..."

if (Get-Module -ListAvailable -Name SkypeOnlineConnector) {
    
    Write-Host "Skype Online Module installed." -ForegroundColor Green

    # Is a session already in place and is it "Opened"?
    if((Get-PSSession | Where-Object {$_.ComputerName -like "*.online.lync.com"}).State -ne "Opened") {

        Write-Host "`nCreating PowerShell session..."

        if ($OverrideAdminDomain) {
            
            $global:PSSession = New-CsOnlineSession -OverrideAdminDomain $OverrideAdminDomain
            
        } else {
            
            $global:PSSession = New-CsOnlineSession

        }
    
        Import-PSSession $global:PSSession -AllowClobber | Out-Null

    }

} else {

    function TeamsConnected {
    
    Get-CsOnlineSipDomain -ErrorAction SilentlyContinue | Out-Null
    $result = $?
    return $result

    }

    if (-not (TeamsConnected)) {

        if (Get-Module -ListAvailable -Name MicrosoftTeams) {
    
            # Connect to Microsoft Teams
            Write-Host "`nTeams module installed" -ForegroundColor Green
            Write-Host "`nCreating PowerShell session..."
            Import-Module MicrosoftTeams
            Import-PSSession -Session (New-CsOnlineSession) | Out-Null
    
        } else {
    
            # Install module and connect to Microsoft Teams
            Write-Host "`nTeams module is not installed" -ForegroundColor Yellow
            Write-Host "`nInstalling module and creating PowerShell session..."
            Install-Module MicrosoftTeams
            Import-PSSession -Session (New-CsOnlineSession) | Out-Null
    
        }

    }

}



# Create function to check for MSOnline session

function MSOLConnected {
    
    Get-MsolDomain -ErrorAction SilentlyContinue | Out-Null
    $result = $?
    return $result

}

# Check if connected to MSOnline
if (-not (MSOLConnected)) {
    
    # Is the module installed?
    if (Get-Module -ListAvailable -Name MSOnline) {
    
        Write-Host "`nMSOnline module installed" -ForegroundColor Green
        Write-Host "`nCreating PowerShell session..."
        Import-Module MSOnline
        Connect-MsolService
    
    } else {
        
        #Install the module if missing
        Write-Host "`nMSOnline module is not installed" -ForegroundColor Yellow
        Write-Host "`nInstalling module and creating PowerShell session..."
        Install-Module MSOnline
        Connect-MsolService
    
    }

}

# Start script loops

$Queues = @()
$Queues = Get-CsCallQueue -WarningAction SilentlyContinue
$CallQueueUsers = @()

foreach ($Queue in $Queues) {
    
    $Users = @()
    $Groups = @()
    $Users = (Get-CsCallQueue -WarningAction SilentlyContinue -Identity $Queue.Identity).Users
    $Groups = (Get-CsCallQueue -WarningAction SilentlyContinue -Identity $Queue.Identity).DistributionLists

    foreach ($User in $Users) {
        
        $QueueUser = @()
        $QueueMsolUser = @()
        $QueueUser = Get-CsOnlineUser -Identity $User.Guid
        $QueueMsolUser = Get-MsolUser -ObjectId $User.Guid
        $QueueUserProperties = @{
            UserDisplayName = $QueueMsolUser.DisplayName
            UserPrincipalName = $QueueMsolUser.UserPrincipalName
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

            if((Get-MsolUser -ObjectId $QueueGroupMember.ObjectId).isLicensed -like "False") {

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

                if(($Member).SipAddress -notlike "sip:*") {

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
                    
                    $MsolMember = Get-MsolUser -ObjectId $QueueGroupMember.ObjectId
                    $MemberProperties = @{
                        UserDisplayName = $MsolMember.DisplayName
                        UserPrincipalName = $MsolMember.UserPrincipalName
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

$CustomObject | Select-Object CallQueue,CallQueueId,ConferenceMode,QueueAssignment,GroupName,UserDisplayName,UserPrincipalName,UserSipAddress | Sort-Object -Property @{Expression="CallQueue"},@{Expression="GroupName"},@{Expression="UserDisplayName"} | Export-Csv -Path $Path -NoTypeInformation

Write-Host "Export saved to " -ForegroundColor Cyan -NoNewline
Write-Host $Path -ForegroundColor Yellow -NoNewline
Write-Host `n
