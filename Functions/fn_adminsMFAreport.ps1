function AdminsMFAReport {
    $results = @()   
    $msolRoles = Get-MsolRole #-ObjectId "62e90394-69f5-4237-9190-012177145e10"   
    foreach ($msolRole in $msolRoles) {
        Write-Host "Searching all users in $($msolRole.Name)..."
        $msolRoleUsers = Get-MsolRoleMember -RoleObjectId $msolRole.ObjectId 
        foreach ($msolRoleUser in $msolRoleUsers) {
            $results += Get-MsolUser -UserPrincipalName $msolRoleUser.EmailAddress | Select-Object @{N='MsolRole';E={$msolRole.Name}},@{N='UserPrincipalName';E={$_.UserPrincipalName}},@{N='DisplayName';E={$_.DisplayName}},@{N='MFAStatus';E={if ($_.StrongAuthenticationRequirements.State){$_.StrongAuthenticationRequirements.State}else{"Disabled"}}},@{N='MFAMethods';E={$_.StrongAuthenticationMethods.methodtype}} 
        }
    }
    Write-Host `n
    $results | ft -AutoSize
}
