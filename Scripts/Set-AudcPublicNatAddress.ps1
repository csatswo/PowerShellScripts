<# 
 .SYNOPSIS
  Set-AUDCPublicNatAddress.ps1
  Updates the NAT translation rules in AudioCodes Mediant SBCs.
  Public IP can be passed via parameter, otherwise automatically discovered via API.
  TODO: Add logic to allow custom ports
  TODO: Add parameters and/or logic to support devices with multiple interfaces or NATs

 .DESCRIPTION
  Downloads current configuration and compares against new public IP. NAT translations not matching new IP are added to
  an incremental INI and uploaded to the device via API. A second API request is sent to "burn" the config.

 .PARAMETER Fqdn
  Required - The FQDN or IP address of the AudioCodes device.

 .PARAMETER PublicIp
  Optional - The public IP to used for NAT translations. If not provided, the script will automatically determine the
  NAT address of the machine running the script.

 .PARAMETER Credential
  Credentials for the AudioCodes device.

 .EXAMPLE
   .\Set-AUDCPublicNatAddress -Fqdn "sbc01.domain.com" -Credential (Get-Credential)
   Prompts for the device credentials at runtime

 .EXAMPLE
   .\Set-AUDCPublicNatAddress -Fqdn "sbc01.domain.com" -Credential (Import-Clixml <path\file.xml>)
   Uses saved credentials from "Get-Credential | Export-Clixml -Path <path\file.xml>"
#>
Param(
    [Parameter(Mandatory=$true)][String]$Fqdn,
    [Parameter(Mandatory=$false)][ValidateScript({ $_ -is [ipaddress] })][ipaddress]$PublicIp,
    [Parameter(Mandatory=$false)][System.Management.Automation.PSCredential]$Credential
)
Begin {
    # Script variables
    $LF        = "`r`n"
    $logFile   = "$PWD\Set-AUDCPublicNatAddress.ps1.log"
    $timeStamp = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
    # Get creds if not provided
    if (! $Credential) { $Credential = Get-Credential }
    # Get public IP if not provided
    if (! $PublicIp) {
        try { $PublicIp = (Invoke-RestMethod -Method Get -Uri "https://api-bdc.net/data/client-ip").ipString }
        catch {
            $failureMsg = "Unable to retrieve public IP from `"https://api-bdc.net/data/client-ip`""
            Add-Content $logFile -Value "$($timeStamp): $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`r$failureMsg`n"
            throw $failureMsg
        }
    }
    # Test connectivity and determine if HTTPS is required
    $http  = [System.Net.Sockets.TcpClient]::new().ConnectAsync($Fqdn, 80).Wait(1000)
    $https = [System.Net.Sockets.TcpClient]::new().ConnectAsync($Fqdn, 443).Wait(1000)
    if (! $http -and ! $https) {
        $failureMsg = "Unable to connect to $fqdn using TCP ports 80 or 443"
        Add-Content $logFile -Value "$($timeStamp): $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`r$failureMsg`n"
        throw $failureMsg
    }
    elseif (! $http -and $https) { $Fqdn = ("https://" + $Fqdn) }
    # Check if host version supports 'SkipCertificateCheck' parameter
    try { Get-Help Invoke-RestMethod -Parameter SkipCertificateCheck -ErrorAction Stop | Out-Null }
    catch { $noSkipCertificateCheck = $true }
}
Process {
    # Create auth header
    $token      = ($Credential.GetNetworkCredential().Username + ":" + $Credential.GetNetworkCredential().Password)
    $authHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($token))}
    # Get and inspect current config and create hash table from current settings
    # AUDC documentation claims a maximum of 32 NAT translations can be configured
    try {
        if ($noSkipCertificateCheck) { $currentConfig = Invoke-RestMethod -Method Get -Headers $authHeader -Uri $($fqdn + "/api/v1/files/cliScript") -ErrorAction Stop }
        else { $currentConfig = Invoke-RestMethod -Method Get -Headers $authHeader -Uri $($fqdn + "/api/v1/files/cliScript") -ErrorAction Stop }
    }
    catch {
        $failureMsg = "$($Error[0].Exception.Message)`nPowerShell version does not support `'SkipCertificateCheck' parameter."
        Add-Content $logFile -Value "$($timeStamp): $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`r$failureMsg`n"
        throw $failureMsg
    }
    $natIndexes = ($currentConfig -split 'nat-translation').Count -1   
    $natTranslations = @{}
    if ($natIndexes -ge 1) {
        (0..$($natIndexes -1)) | % {
            $natRule = (($currentConfig -split "nat-translation {0}" -f $_)[1] -split 'activate')[0]
            $natTranslations.Add("nat-translation {0}" -f $_,"")
            $value = [PSCustomObject]@{}
            $natRule.Split("`n") | % { if ($_ -match '\w.*') { $value | Add-Member -NotePropertyName ($_.Trim() -split " ")[0] -NotePropertyValue (($_.Trim() -split " ")[1] -replace '"') } }
            $value | Add-Member -NotePropertyName "target-ip-address-new" -NotePropertyValue $PublicIp.ToString()
            $natTranslations["nat-translation {0}" -f $_] = $value
        }
    }
    # Prepare CLI script for incremental INI
    $cliData = @("configure network")
    $natTranslations.Keys | Sort-Object | % {
        if ($natTranslations[$_].'target-ip-address' -ne $natTranslations[$_].'target-ip-address-new') {
            $cliData += @(
                " $_"
                " src-interface-name `"$($natTranslations[$_].'src-interface-name')`""
                " target-ip-address `"{0}`"" -f $natTranslations[$_].'target-ip-address-new'
                " src-start-port `"$($natTranslations[$_].'src-start-port')`""
                " src-end-port `"$($natTranslations[$_].'src-end-port')`""
                " activate"
                " exit"
            )
        }
    }
    $cliScript = $cliData -join $LF
    # Prepare body API request using CLI script
    $boundary = [System.Guid]::NewGuid().ToString()
    $bodyLines = @(
        "--$boundary"
        "Content-Disposition: form-data; name=`"file`";" + " filename=`"file.txt`""
        "Content-Type: application/octet-stream$LF"
        $cliScript
        "--$boundary--$LF"
    ) -join $LF
    # Set new public IP
    try {
        if ($cliData -match "target-ip-address") {
            $putResults = Invoke-RestMethod -Method Put -Headers $authHeader -Uri $($fqdn + "/api/v1/files/cliScript/incremental") -ContentType "multipart/form-data; boundary=$boundary" -Body $bodyLines -ErrorAction Stop
            $logMessage = "$($putResults.status + ": " + $putResults.description)`n$($natTranslations.Values | ConvertTo-Json)`nCLI Script:`n$($cliScript)"
            Add-Content $logFile -Value "$($timeStamp): $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`r$logMessage`n"
        }
        else {
            $logMessage = "No changes made.`n$($natTranslations.Values | ConvertTo-Json)`nCLI Script:`nN/A"
            Add-Content $logFile -Value "$($timeStamp): $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`r$logMessage`n"
            Break
        }
    }
    catch {
        $failureMsg = $($Error[0].Exception.Message)
        Add-Content $logFile -Value "$($timeStamp): $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`r$failureMsg`n"
        throw $Error[0]
    }
}
End {
    try {
        Write-Output $($putResults.status + ": " + $putResults.description)
        Write-Output "Saving config..."
        Invoke-RestMethod -Method Post -Headers $authHeader -Uri $($fqdn + "/api/v1/actions/saveConfiguration") -ErrorAction Stop | Out-Null
        Write-Output "Done!"
    }
    catch {
        $failureMsg = $($Error[0].Exception.Message)
        Add-Content $logFile -Value "$($timeStamp): $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`r$failureMsg`n"
        throw $Error[0]
    }
}
