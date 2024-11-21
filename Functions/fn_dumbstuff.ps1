Function whatismyip {
    Invoke-RestMethod -Method Get -Uri "4.ident.me"
}
Function FirstLetters {
    [CmdletBinding()]Param([string]$String)
    $firstLetters = @()
    foreach ($wordStr in (($String.ToLower() -split " ") -replace "\W")) {
        $firstLetters += $wordStr.Substring(0,1)
    }
    $firstLetters -join ""
}

function DLTeamsNetAssess {
    [CmdletBinding()]Param([Parameter(Mandatory=$true)][ValidateScript({ if (Test-Path $_){ $true } else { throw "Path $_ is not valid" } })][string]$Folder)
    Write-Output "Downloading the Microsoft Teams Network Assessment Tool..."
    $downloadPage = Invoke-WebRequest -UseBasicParsing -Uri 'https://www.microsoft.com/en-us/download/confirmation.aspx?id=103017'
    $downloadLink = ($DownloadPage.Links | Where-Object {$_.href -like '*MicrosoftTeamsNetworkAssessmentTool.exe'}).href[0]
    Invoke-WebRequest -UseBasicParsing -Uri $downloadLink -OutFile $Folder\MicrosoftTeamsNetworkAssessmentTool.exe
}
