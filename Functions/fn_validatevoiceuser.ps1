Function ValidateVoiceUser {
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]$UserPrincipalName
    )
    Process {
        try {
            $csUser = Get-CsOnlineUser -Identity $UserPrincipalName -ErrorAction SilentlyContinue
            if ($csUser) {
                if (-not ($csUser.AccountEnabled)) {
                    Write-Verbose "$($csUser.UserPrincipalName) is not enabled"
                    $validVoiceUser = $false
                }
                elseif (-not ($csUser.AssignedPlan)) {
                    Write-Verbose "$($csUser.UserPrincipalName) is not licensed properly"
                    $validVoiceUser = $false
                }
                elseif (-not ($csUser.AssignedPlan.Capability -contains "Teams")) {
                    Write-Verbose "$($csUser.UserPrincipalName) is not licensed properly"
                    $validVoiceUser = $false
                }
                else {
                    $userLicenses = @{}
                    foreach ($assignedPlan in $csUser.AssignedPlan) { $userLicenses.Add($assignedPlan.Capability,$assignedPlan) }
                    if (($userLicenses["Teams"]).CapabilityStatus -ne "Enabled") {
                        Write-Verbose "$($csUser.UserPrincipalName) is not licensed properly"
                        $validVoiceUser = $false
                    }
                    else {
                        $validVoiceUser = $true
                    }
                }
            }
            else {
                Write-Verbose $($Error[0].Exception)
                $validVoiceUser = $false
            }
        } catch {
            $($Error[0].Exception)
        }
    }
    End {
        Return $validVoiceUser
    }
}
