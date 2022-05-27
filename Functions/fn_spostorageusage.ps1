function SPOUsageTeams {
    $spSites = Get-SPOSite -IncludePersonalSite $true -Limit all | Where-Object {$_.IsTeamsConnected -eq $true -or $_.IsTeamsChannelConnected -eq $true}
    $customObject = @()
    foreach ($spSite in $spSites) {
        $customProps =@{
            Status = $spSite.Status
            URL = $spSite.Url
            Type = "Site"
            Quota = $spSite.StorageQuota
            Usage = $spSite.StorageUsageCurrent
            Team = $spSite.IsTeamsConnected
            Channel = $spSite.IsTeamsChannelConnected
            ChannelType = $spSite.TeamsChannelType
            }
        $customObject += New-Object -TypeName PSObject -Property $customProps
    }
    $customObject | Sort-Object URL | Select-Object Status,URL,Type,Quota,Usage,Teams,Channel,ChannelType | ft -AutoSize
}

function SPOUsageODB {
    $odbSites = Get-SPOSite -IncludePersonalSite $true -Limit all | Where-Object {$_.Url -like "*.sharepoint.com/personal/*"}
    $customObject = @()
    foreach ($odbSite in $odbSites) {
        $customProps =@{
            Status = $odbSite.Status
            URL = $odbSite.Url
            Type = "ODB"
            Quota = $odbSite.StorageQuota
            Usage = $odbSite.StorageUsageCurrent
            }
        $customObject += New-Object -TypeName PSObject -Property $customProps
    }
    $customObject | Sort-Object URL | Select-Object Status,URL,Type,Quota,Usage | ft -AutoSize
}
