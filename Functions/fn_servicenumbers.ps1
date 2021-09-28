function ServiceNumbers {
    $serviceNumbers = Get-CsOnlineTelephoneNumber | Where-Object {$_.InventoryType -ne "Subscriber"}
    $customObject = @()
    foreach ($serviceNumber in $serviceNumbers) {
        if ($serviceNumber.TargetType -ne $null) {
            $appId = Get-CsOnlineApplicationInstance | Where-Object {$_.PhoneNumber -like ("tel:+"+$serviceNumber.Id)}
            $customProperties = @{
                Id = $serviceNumber.Id
                InventoryType = $serviceNumber.InventoryType
                ActivationState = $serviceNumber.ActivationState
                PortInOrderStatus = $serviceNumber.PortInOrderStatus
                TargetType = $serviceNumber.TargetType
                ResourceAccount = $appId.DisplayName
                UserPrincipalName = $appId.UserPrincipalName
            }
        $customObject += New-Object -TypeName PSObject -Property $customProperties
        } else {
            $customProperties = @{
                Id = $serviceNumber.Id
                InventoryType = $serviceNumber.InventoryType
                ActivationState = $serviceNumber.ActivationState
                PortInOrderStatus = $serviceNumber.PortInOrderStatus
                TargetType = $serviceNumber.TargetType
                ResourceAccount = "N/A"
                UserPrincipalName = "N/A"
            }
            $customObject += New-Object -TypeName PSObject -Property $customProperties
        }
    }
    $customObject | Sort-Object InventoryType,Id | Select-Object Id,InventoryType,ActivationState,PortInOrderStatus,TargetType,ResourceAccount,UserPrincipalName | ft -AutoSize
}