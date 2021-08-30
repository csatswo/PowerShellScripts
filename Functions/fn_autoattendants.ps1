Function AAResourceAccounts {
param([Parameter(mandatory=$true)][String]$Name)
$resourceAccountAA = Get-CsAutoAttendant | Where-Object {$_.Name -like "$Name"}
$resourceAccounts = $resourceAccountAA.ApplicationInstances
$assignedAccounts = @()
if ($resourceAccounts) {
    foreach ($resourceAccount in $resourceAccounts) {
        $appInstance = Get-CsOnlineApplicationInstance -Identity $resourceAccount
        $customProperties = @{
            AutoAttendant = $resourceAccountAA.Name
            Name = $appInstance.DisplayName
            UPN = $appInstance.UserPrincipalName
            Number = $appInstance.PhoneNumber}
        $assignedAccounts += New-Object -TypeName PSObject -Property $customProperties}
    $assignedAccounts | Select-Object AutoAttendant,Name,UPN,Number
} else {
Write-Host "`nNo resource accounts found"
}}

Function AAHolidays {
param([Parameter(mandatory=$true)][String]$Name)
$holidayAA = Get-CsAutoAttendant | Where-Object {$_.Name -like "$Name"}
$holidays = Get-CsAutoAttendantHolidays -Identity $holidayAA.Identity -WarningAction SilentlyContinue
$holidaysObject = @()
if ($holidays) {
    foreach ($holiday in $holidays) {
        $startDate = Get-Date $holiday.DateTimeRanges.Start -Format dd-MMM-yyyy
        $endDate = Get-Date $holiday.DateTimeRanges.End -Format dd-MMM-yyyy
        $startTime = Get-Date $holiday.DateTimeRanges.Start -Format HH:mm
        $endTime = Get-Date $holiday.DateTimeRanges.End -Format HH:mm
        $customProperties = @{
            AutoAttendant = $holidayAA.Name
            Name = $holiday.Name
            StartDate = $startDate
            StartTime = $startTime
            EndDate = $endDate
            EndTime = $endTime}
        $holidaysObject += New-Object -TypeName PSObject -Property $customProperties}
    $holidaysObject | Select-Object AutoAttendant,Name,StartDate,StartTime,EndDate,EndTime | Format-Table -AutoSize
} else {
Write-Host "`nNo holidays are configured for $($holidayAA.Identity)"
}}
