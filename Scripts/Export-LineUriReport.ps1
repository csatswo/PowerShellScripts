Clear-Host
# Audit the Resource Account licenses and export a report of issues
$appInstanceLicenseIssues = [System.Collections.ArrayList]@()
$appInstanceList = [System.Collections.ArrayList]@()
Write-Output `n
Write-Output "Auditing resource accounts. This may take a moment."
Get-CsOnlineApplicationInstance | foreach {
    $u = Get-CsOnlineUser -Identity $_.UserPrincipalName
    [void]$appInstanceList.Add($u.UserPrincipalName)
    if ($u.ProvisionedPlan) {
        if ($u.ProvisionedPlan.Capability -ne "MCOEV_VIRTUALUSER") {
            $obj = [PSCustomObject]@{
                DisplayName = $u.DisplayName
                UserPrincipalName = $u.UserPrincipalName
                Issue = "Wrong License(s)"
                Licenses = ($u.ProvisionedPlan.Capability -join ";")
            }
            [void]$appInstanceLicenseIssues.Add($obj)
        }
    } else {
        $obj = [PSCustomObject]@{
            DisplayName = $u.DisplayName
            UserPrincipalName = $u.UserPrincipalName
            Issue = "Not Licensed"
            Licenses = $null
        }
        [void]$appInstanceLicenseIssues.Add($obj)
    }
}
$timeStamp = Get-Date -Format "yyyy-dd-MM-HHmmss"
$path = "$PWD\application_instance_issues_$timeStamp.csv"
$appInstanceLicenseIssues | Export-Csv -Path $path -NoTypeInformation
if ($appInstanceLicenseIssues) {
    Write-Output `n
    Write-Output "There are [$($appInstanceLicenseIssues.Count)] resource accounts with license issues."
}
Write-Output `n
Write-Output "Report of Application Instance license issues saved to:"
Write-Output "  $path"
# Audit User Accounts
$telUsersList = [System.Collections.ArrayList]@()
Write-Output `n
Write-Output "Auditing users with LineURIs. This may take a moment."
Get-CsOnlineUser | ? {$null -ne $_.LineUri} | foreach -PV u {$_} | foreach {
    if ($u.LineUri -like "*;ext=*") {
        $beforeExt = ($u.LineUri -split ";ext=")[0]
        $afterExt = ($u.LineUri -split ";ext=")[1]
        $lastDigits = $beforeExt.Substring($beforeExt.Length - $afterExt.Length)
        if ($lastDigits -ne $afterExt ) { $comment = "Number/Extension mismatch" }
        else {
            if ($u.AccountType -eq "ResourceAccount") { $comment = "Resource Account" }
            else { $comment = $null }
        }
    }
    else {
        if ($u.AccountType -eq "ResourceAccount") { $comment = $null }
        else { $comment = "Missing EXT" }
    }
    $obj = [PSCustomObject]@{
        AccountType = $u.AccountType
        DisplayName = $u.DisplayName
        UserPrincipalName = $u.UserPrincipalName
        LineUri = $u.LineUri
        Comment = $comment
    }
    [void]$telUsersList.Add($obj)
}
$timeStamp = Get-Date -Format "yyyy-dd-MM-HHmmss"
$path = "$PWD\lineuri_report_$timeStamp.csv"
$telUsersList | Export-Csv -Path $path -NoTypeInformation
if ($telUsersList | ? {$_.AccountType -eq "ResourceAccount" -and $_.LineUri -notlike "*;ext=*"}) {
    Write-Output `n
    Write-Output "There are [$(($telUsersList | ? {$_.AccountType -eq "ResourceAccount" -and $_.LineUri -notlike "*;ext=*"}).Count)] Resource Accounts without extensions."
}
if ($telUsersList | ? {$null -ne $_.Comment}) {
    Write-Output `n
    Write-Output "There are [$(($telUsersList | ? {$null -ne $_.Comment}).Count)] users with extension issues."
}
Write-Output `n
Write-Output "LineURI Report license issues saved to:"
Write-Output "  $path"

<#
# Script to update/fix LineURIs
$telUsersList | ? {$null -ne $_.Comment} | foreach {
    # Number of digits to use for extension
    $extLength = 4
    # Format and assign new LineURI with matching extension
    $number = (($_.LineUri -replace "tel:") -split ";ext=")[0]
    $extension = $number.Substring($number.Length - $extLength)
    $lineUri = ($number + ";ext=" + $extension)
    Set-CsPhoneNumberAssignment -Identity $_.UserPrincipalName -PhoneNumber $lineUri -PhoneNumberType DirectRouting
}
#>
