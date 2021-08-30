Function recent {
    [CmdletBinding()]Param([string] $search)
    Get-History | ? {$_.CommandLine -like "*$search*"}
}

Function again {
    [CmdletBinding()]Param([string] $id)
    Invoke-History $id
}