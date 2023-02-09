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
                    Write-Verbose "$($csUser.UserPrincipalName) is not licensed"
                    $validVoiceUser = $false
                }
                else {
                    $userLicenses = @{}
                    foreach ($assignedPlan in $csUser.AssignedPlan) { $userLicenses.Add($assignedPlan.Capability,$assignedPlan) }
                    if ($userLicenses.Keys -contains "MCOEV_VIRTUALUSER" -and $true -eq ($userLicenses["MCOEV_VIRTUALUSER"]).CapabilityStatus) {
                        # Licensed for Teams Virtual User
                        Write-Verbose "$($csUser.UserPrincipalName) is licensed as Resource Account"
                        $validVoiceUser = $true
                    }
                    elseif ($userLicenses.Keys -notcontains "Teams") {
                        # Not licensed for Teams
                        Write-Verbose "$($csUser.UserPrincipalName) is not licensed for Teams"
                        $validVoiceUser = $false
                    }
                    elseif ($userLicenses.Keys -notcontains "MCOEV") {
                        # Licensed for Teams but not Phone System
                        Write-Verbose "$($csUser.UserPrincipalName) is not licensed for Phone System"
                        $validVoiceUser = $false
                    }
                    elseif (-not (($userLicenses["Teams"]).CapabilityStatus -eq "Enabled" -and ($userLicenses["MCOEV"]).CapabilityStatus -eq "Enabled")) {
                        $teamsLicense = (($userLicenses["Teams"]).CapabilityStatus -eq "Enabled")
                        $voiceLicense = (($userLicenses["MCOEV"]).CapabilityStatus -eq "Enabled")
                        if ($false -eq $teamsLicense -and $false -eq $voiceLicense) {
                            # Licenses were removed
                            Write-Verbose "$($csUser.UserPrincipalName) is not licensed for Teams or Phone System"
                            $validVoiceUser = $false
                        }
                        if ($true -eq $teamsLicense -and $false -eq $voiceLicense) {
                            # License for Phone System was removed
                            Write-Verbose "$($csUser.UserPrincipalName) is not licensed for Phone System"
                            $validVoiceUser = $false
                        }
                        if ($false -eq $teamsLicense -and $true -eq $voiceLicense) {
                            # License for Teams was removed
                            Write-Verbose "$($csUser.UserPrincipalName) is not licensed for Teams"
                            $validVoiceUser = $false
                        }
                    }
                    else {
                        # Licensed for Teams and Phone System
                        Write-Verbose "$($csUser.UserPrincipalName) is licensed as Teams voice user"
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
