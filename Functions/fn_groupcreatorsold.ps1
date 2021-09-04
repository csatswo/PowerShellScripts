Function GroupCreatorsOld {
$groupCreatorUsers = @()
$groupCreatorGroups = @()
$settingsObjectID = (Get-AzureADDirectorySetting | Where-object -Property Displayname -Value "Group.Unified" -EQ).id
if(!$settingsObjectID) {
    Write-Host "`nGroup Creators is not configured" -ForegroundColor Yellow
} else {
    Write-Host "`nGroup Creators is configured" -ForegroundColor Green
    $groupCreationAllowedGroupId = ((Get-AzureADDirectorySetting -Id $settingsObjectID).Values | Where-Object {$_.Name -eq "GroupCreationAllowedGroupId"}).Value
    $groupCreationAllowedGroup = Get-AzureADGroup -ObjectId $groupCreationAllowedGroupId
    $groupCreationAllowedGroupMembers = Get-AzureADGroupMember -ObjectId $groupCreationAllowedGroupId | Where-Object {$_.ObjectType -eq "User"}
    $groupCreationAllowedGroupNestedGroups = Get-AzureADGroupMember -ObjectId $groupCreationAllowedGroupId | Where-Object {$_.ObjectType -eq "Group"}
    foreach ($groupCreationAllowedGroupMember in $groupCreationAllowedGroupMembers) {
        $customProperties = @()
        $customProperties = @{
            DisplayName = $groupCreationAllowedGroupMember.DisplayName
            UserPrincipalName = $groupCreationAllowedGroupMember.UserPrincipalName
            GroupName = $groupCreationAllowedGroup.DisplayName}
        $groupCreatorUsers += New-Object -TypeName PSObject -Property $customProperties
    }
    Write-Host "Group Name: " -ForegroundColor Green -NoNewline
    Write-Host $groupCreationAllowedGroup.DisplayName -ForegroundColor Yellow
    $groupCreatorUsers | Select-Object DisplayName,UserPrincipalName,GroupName | Sort-Object -Property DisplayName | Format-Table -AutoSize
    $groupCreationAllowedGroupNestedGroups = Get-AzureADGroupMember -ObjectId $groupCreationAllowedGroupId | Where-Object {$_.ObjectType -eq "Group"}
    if($groupCreationAllowedGroupNestedGroups) {
        Write-Host "`nNested groups found" -ForegroundColor Green
        foreach ($groupCreationAllowedGroupNestedGroup in $groupCreationAllowedGroupNestedGroups) {
            Write-Host "Nested group name: " -ForegroundColor Green -NoNewline
            Write-Host $groupCreationAllowedGroupNestedGroup.DisplayName -ForegroundColor Yellow
            $customProperties = @()
            $customProperties = @{
                DisplayName = $groupCreationAllowedGroupNestedGroup.DisplayName
                Description = $groupCreationAllowedGroupNestedGroup.Description
                ObjectId = $groupCreationAllowedGroupNestedGroup.ObjectId}
            $groupCreatorGroups += New-Object -TypeName PSObject -Property $customProperties
        }
    $groupCreatorGroups | Select-Object DisplayName,ObjectId,Description | Sort-Object -Property DisplayName | Format-Table -AutoSize
    }
}

}