Function UserJsonHashTable {
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true)][string]$File
    )
    $json = Get-Content -Raw -Path $File | ConvertFrom-Json
    $hashTable = @{}
    foreach ($object in $json) {
        if ($object.UserPrincipalName -notlike $null) {
            $hashTable.Add($object.UserPrincipalName,$object)
        }
    }
    $hashTable
}
