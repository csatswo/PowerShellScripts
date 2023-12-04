Function Get-CsPhoneNumberUserAssignment {
    [CmdletBinding()]Param ([Parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $true)]
    [ValidatePattern('^\+?\d+$')]
    [string]$Number)
    if ($number -like "+*") { $numAssignments = Get-CsPhoneNumberAssignment -TelephoneNumber $number }
    else { $numAssignments = Get-CsPhoneNumberAssignment -TelephoneNumberContain $number }
    $numAssignments | % {
        if (-not $_.AssignedPstnTargetId) { $_ | Add-Member -NotePropertyName UserPrincipalName -NotePropertyValue $null }
        else { $_ | Add-Member -NotePropertyName UserPrincipalName -NotePropertyValue $(Get-CsOnlineUser -Identity $_.AssignedPstnTargetId).UserPrincipalName }
    }
    $numAssignments | Select-Object *
}