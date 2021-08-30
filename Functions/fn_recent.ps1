Function recent {
    [CmdletBinding()]Param([string] $search)
    Get-History | Where-Object {$_.CommandLine -like "*$search*"}
}

Function again {
    [CmdletBinding()]Param([string] $id)
    Invoke-History $id
}