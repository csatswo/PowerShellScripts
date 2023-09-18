$tenant = "demo"

$timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
$outputFolder = New-Item -Path $PWD\$($tenant)_$($timestamp) -ItemType Directory

$csOnlineUsers = Get-CsOnlineUser
$csOnlineUsers | ConvertTo-Json -Depth 100 | Out-File "$($outputFolder.FullName)\$($tenant)_CsOnlineUsers.json"

foreach ($policyCmdlet in (Get-Command get-cs*policy).Name) {
    # Write-Output $policyCmdlet
    & $policyCmdlet | ConvertTo-Json -Depth 100 | Out-File "$($outputFolder.FullName)\$($tenant)_$($policyCmdlet).json"
}

Get-CsGroupPolicyAssignment | ConvertTo-Json -Depth 100 | Out-File "$($outputFolder.FullName)\$($tenant)_Get-CsGroupPolicyAssignment.json"
