<#
The available dial-out policies are listed below.  The Global policy can be changed to match 
any of the other policies.  The Global policy is assigned to any user without an assigned    
policy.
    PolicyName                          Conferencing Dialout             PSTN Outbound           
    --------                            -------------------------------- ------------------------
    Global                              InternationalAndDomestic         InternationalAndDomestic
    DialoutCPCandPSTNInternational      InternationalAndDomestic         InternationalAndDomestic
    DialoutCPCDomesticPSTNInternational DomesticOnly                     InternationalAndDomestic
    DialoutCPCDisabledPSTNInternational Disabled                         InternationalAndDomestic
    DialoutCPCInternationalPSTNDomestic InternationalAndDomestic         DomesticOnly            
    DialoutCPCInternationalPSTNDisabled InternationalAndDomestic         Disabled                
    DialoutCPCandPSTNDomestic           DomesticOnly                     DomesticOnly            
    DialoutCPCDomesticPSTNDisabled      DomesticOnly                     Disabled                
    DialoutCPCDisabledPSTNDomestic      Disabled                         DomesticOnly            
    DialoutCPCandPSTNDisabled           Disabled                         Disabled                
    DialoutCPCZoneAPSTNInternational    ZoneA                            InternationalAndDomestic
    DialoutCPCZoneAPSTNDomestic         ZoneA                            DomesticOnly            
    DialoutCPCZoneAPSTNDisabled         ZoneA                            Disabled                
#>              

<#
  This script will assign the "Global" policy to all normal users with a phone number.
  Resource accounts will be assigned the "DialoutCPCDisabledPSTNDomestic" policy to disable conferencing
  dial-out but allow domestic calling. Resource accounts assigned to Auto Attendants may need outbound 
  PSTN enabled in the event a menu options uses external transfers.
#>

Get-CsOnlineUser -Filter {LineUri -ne $null} | ForEach-Object {
    if ($_.AccountType -eq "User") {
        if ($_.OnlineDialOutPolicy -ne $null) {
            Write-Output "Updating $($_.UserPrincipalName) from $($_.OnlineDialOutPolicy) to Global"
            Grant-CsDialoutPolicy -Identity $_.UserPrincipalName -PolicyName $null
        }
    }
    if ($_.AccountType -eq "ResourceAccount") {
        if ($_.OnlineDialOutPolicy -ne "") {
            Write-Output "Updating $($_.UserPrincipalName) from $($_.OnlineDialOutPolicy) to DialoutCPCDisabledPSTNDomestic"
            Grant-CsDialoutPolicy -Identity $_.UserPrincipalName -PolicyName "DialoutCPCDisabledPSTNDomestic"
        }
    }
}
