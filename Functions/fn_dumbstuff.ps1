Function FirstLetters {
    [CmdletBinding()]Param([string]$String)
    $firstLetters = @()
    foreach ($wordStr in (($String.ToLower() -split " ") -replace "\W")) {
        $firstLetters += $wordStr.Substring(0,1)
    }
    $firstLetters -join ""
}