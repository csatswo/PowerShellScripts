function Test-SslCert {
    [CmdletBinding()]Param (
        [Parameter(Mandatory = $true)][string]$Fqdn,
        [Parameter(mandatory = $false)][int]$Port
    )
    # Allow connection to sites with an invalid certificate:
    [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
    $timeoutMilliseconds = 5000
    $url = "https://$fqdn"
    $req = [Net.HttpWebRequest]::Create($url)
    $req.Timeout = $timeoutMilliseconds
    if (Test-NetConnection -ComputerName $fqdn -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue) {
        Try {
            $req.GetResponse() | Out-Null
            if ($req.ServicePoint.Certificate -ne $null) {
                $cert = New-Object security.cryptography.x509certificates.x509certificate2($req.ServicePoint.Certificate)
                $results = [PSCustomObject]@{
                    Subject      = $certinfo.Subject
                    FriendlyName = $certinfo.FriendlyName
                    Issuer       = $certinfo.Issuer
                    NotBefore    = $certinfo.NotBefore
                    NotAfter     = $certinfo.NotAfter
                    SerialNumber = $certinfo.SerialNumber
                    Thumbprint   = $certinfo.Thumbprint
                    DnsNameList  = $($certinfo.DnsNameList.Punycode | Sort-Object)
                }
                $results
            }
        }
        Catch {
            Throw $Error[0].Exception
        }
    }
    else {
        Throw "Unable to connect to FQDN [$fqdn] on port [$port]"
    }
}
