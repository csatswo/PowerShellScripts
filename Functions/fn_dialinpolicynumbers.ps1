Function DialinPolicyNumbers {
    $results = @()
    $confPolicies = Get-CsTeamsAudioConferencingPolicy
    foreach ($policy in $confPolicies) {
        if (-not ($policy.MeetingInvitePhoneNumbers)) {
            $results += [PSCustomObject]@{
                Policy = $policy.Identity
                Number = $null
                Index = $null
            }        
        } else {
            foreach ($phoneNumber in $policy.MeetingInvitePhoneNumbers) {
                $results += [PSCustomObject]@{
                    Policy = $policy.Identity
                    Number = [string]$phoneNumber
                    Index = [int]$policy.MeetingInvitePhoneNumbers.IndexOf($phoneNumber)
                }
            }
        }
    }
    $results
}
