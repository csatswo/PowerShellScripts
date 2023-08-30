Function GroupCreators {
    Function EnumerateGroupCreatorsGroups {
        [cmdletbinding()]
        param(
            [parameter(Mandatory=$true,ValueFromPipeline=$true)]$Group,
            [parameter(Mandatory=$false,ValueFromPipeline=$true)]$ParentGroup,
            [parameter(Mandatory=$true,ValueFromPipeline=$true)]$Iteration
        )
        Process {
            $groupCreatorUsers = @()
            $members = Get-AzureADGroupMember -ObjectId $Group.ObjectId
            if ($Iteration -eq 0) {
                Write-Verbose "Enumerating $($Group.DisplayName)"
                foreach ($member in ($members | Where-Object {$_.ObjectType -eq "User"})) {
                    $member | Add-Member -NotePropertyName MembershipGroup -NotePropertyValue $Group.DisplayName
                    $member | Add-Member -NotePropertyName GroupId -NotePropertyValue $Group.ObjectId
                    $member | Add-Member -NotePropertyName ParentGroup -NotePropertyValue $null
                    $groupCreatorUsers += $member
                }
            } else {
                Write-Verbose "Enumerating $($Group.DisplayName)"
                foreach ($member in ($members | Where-Object {$_.ObjectType -eq "User"})) {
                    $member | Add-Member -NotePropertyName MembershipGroup -NotePropertyValue $Group.DisplayName
                    $member | Add-Member -NotePropertyName GroupId -NotePropertyValue $Group.ObjectId
                    $member | Add-Member -NotePropertyName ParentGroup -NotePropertyValue $ParentGroup
                    $groupCreatorUsers += $member
                }
            }
            if ($members | Where-Object {$_.ObjectType -eq "Group" -and $Iteration -eq 0}) {
                Write-Warning "Nested groups discovered. This script will enumerate all nested groups recursively. This may cause the script to loop indefinitely."
                $members | Where-Object{$_.ObjectType -eq "Group"} | ForEach-Object {
                    $Iteration++
                    EnumerateGroupCreatorsGroups -Group $_ -Iteration $Iteration -ParentGroup $Group.DisplayName -Verbose
                }
            } elseif ($members | Where-Object {$_.ObjectType -eq "Group"}) {
                $members | Where-Object{$_.ObjectType -eq "Group"} | ForEach-Object {
                    $Iteration++
                    EnumerateGroupCreatorsGroups -Group $_ -Iteration $Iteration -ParentGroup $Group.DisplayName -Verbose
                }
            }
        }
        End {
            Return $groupCreatorUsers
        }
    }
    try {
        $aadUnifiedGroupSettings = (Get-AzureADDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ)
        $aadUnifiedGroupSettingsValues = $aadUnifiedGroupSettings.Values
        if (!($aadUnifiedGroupSettingsValues | Where-Object {$_.Name -eq 'EnableGroupCreation'}).Value) {
                Write-Output "`nUnified Group settings are configured but group creation is not restricted."
            if (($aadUnifiedGroupSettingsValues | Where-Object {$_.Name -eq 'GroupCreationAllowedGroupId'}).Value) {
                $groupCreationAllowedGroup = Get-AzureADGroup -ObjectId ($aadUnifiedGroupSettingsValues | Where-Object {$_.Name -eq 'GroupCreationAllowedGroupId'}).Value
                Write-Output "The `'$($groupCreationAllowedGroup.DisplayName)`' group is assigned."
                $groupCreatorUsers = @()
                $groupCreatorUsers = EnumerateGroupCreatorsGroups -Group $groupCreationAllowedGroup -Iteration 0 -Verbose | Sort-Object ParentGroup,MembershipGroup,UserPrincipalName | Select-Object DisplayName,UserPrincipalName,UserType,MembershipGroup,GroupID,ParentGroup
                $groupCreatorUsers | ft -AutoSize
            } else {
                Write-Output "No group is assigned."
                $aadUnifiedGroupSettingsValues
            }
        } else {
            Write-Output "`nUnified Group settings are configured and group creation is restricted."
            if ($aadUnifiedGroupSettingsValues | Where-Object {$_.Name -eq 'GroupCreationAllowedGroupId'}) {            
                $groupCreationAllowedGroup = Get-AzureADGroup -ObjectId ($aadUnifiedGroupSettingsValues | Where-Object {$_.Name -eq 'GroupCreationAllowedGroupId'}).Value
                Write-Output "The `'$($groupCreationAllowedGroup.DisplayName)`' group is assigned.`n"
                $groupCreatorUsers = @()
                $groupCreatorUsers = EnumerateGroupCreatorsGroups -Group $groupCreationAllowedGroup -Iteration 0 -Verbose | Sort-Object ParentGroup,MembershipGroup,UserPrincipalName | Select-Object DisplayName,UserPrincipalName,UserType,MembershipGroup,GroupID,ParentGroup
                $groupCreatorUsers | ft -AutoSize
            } else {
                Write-Warning "No group is assigned."
                $aadUnifiedGroupSettingsValues
            }
        }
    
    } catch {
        Write-Output "`nNo Unified Group settings configured`n"
    }
}
