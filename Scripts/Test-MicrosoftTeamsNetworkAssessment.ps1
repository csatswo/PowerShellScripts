<# 
.SYNOPSIS

    Downloads, installs, and runs the Microsoft Teams Network Assessment tool.
    Adds all resulting files, including the normal console output, to a single ZIP on the users desktop.

.DESCRIPTION

    Downloads, installs, and runs the Microsoft Teams Network Assessment tool.
    Adds all resulting files, including the normal console output, to a single ZIP on the users desktop.

.PARAMETER Site

    The name of the site being tested. For example: "Los Angeles" or "Site01".

.EXAMPLE

    .\Test-MicrosoftTeamsNetworkAssessment -Site "Site01"
#>
Param(
    [Parameter(mandatory=$true)][String]$Site
)
$siteClean = ($site -replace " " -replace "`"").Trim()
$downloadPage = Invoke-WebRequest -UseBasicParsing -Uri 'https://www.microsoft.com/en-us/download/confirmation.aspx?id=103017'
$downloadLink = ($DownloadPage.Links | Where-Object {$_.href -like '*MicrosoftTeamsNetworkAssessmentTool.exe'}).href[0]
$tempFolder = (New-Item -ItemType Directory -Path ("$env:TEMP" + "\MicrosoftTeamsNetworkAssessmentTool_" + (Get-Date -Format yyyyMMddHHmmssffff))).FullName
Write-Host "`nDownloading the Microsoft Teams Network Assessment Tool..." -ForegroundColor Cyan
Invoke-WebRequest -UseBasicParsing -Uri $downloadLink -OutFile $tempFolder\MicrosoftTeamsNetworkAssessmentTool.exe
Write-Warning -Message "The tool will be installed using the default installation path of `'%ProgramFiles(x86)%\Microsoft Teams Network Assessment Tool\`'"
Write-Host "`nInstalling the Microsoft Teams Network Assessment Tool..." -ForegroundColor Cyan
Start-Process "$tempFolder\MicrosoftTeamsNetworkAssessmentTool.exe" /passive -Wait
Remove-Item -Path $tempFolder\MicrosoftTeamsNetworkAssessmentTool.exe
Write-Host "`nRunning the connectivity check. This may take a few minutes." -ForegroundColor Cyan
$hostOutput = & "${env:ProgramFiles(x86)}\Microsoft Teams Network Assessment Tool\NetworkAssessmentTool.exe" | Tee-Object ($tempFolder + "\" + (Get-Date -Format yyyyMMddHHmmssffff) + "_service_connectivity_check_terminal.txt")
$startIndex = ($hostOutput[$hostOutput.Count-1]).indexof('C:\')
$length = (($hostOutput[$hostOutput.Count-1]).Length) - $startIndex
$result = ($hostOutput[$hostOutput.Count-1]).Substring($startIndex,$length)
Move-Item $result -Destination $tempFolder
Write-Host `n
$hostOutput[0..($hostOutput.Count-2)]
Write-Host "`nRunning the quality check. This should take 5 minutes." -ForegroundColor Cyan
$hostOutput = & "${env:ProgramFiles(x86)}\Microsoft Teams Network Assessment Tool\NetworkAssessmentTool.exe" /qualitycheck | Tee-Object ($tempFolder + "\" + (Get-Date -Format yyyyMMddHHmmssffff) + "_quality_check_terminal.txt")
$startIndex = ($hostOutput[$hostOutput.Count-1]).indexof('C:\')
$length = (($hostOutput[$hostOutput.Count-1]).Length) - $startIndex
$result = ($hostOutput[$hostOutput.Count-1]).Substring($startIndex,$length)
Move-Item $result -Destination $tempFolder
$metrics = $hostOutput | Where-Object {$_ -like '*Loss Rate:*'}
$lossRateArray = @()
$latencyArray = @()
$jitterArray = @()
foreach ($metric in $metrics) {
    $lossRateArray += [double]($metric.Substring(($metric.IndexOf('Loss Rate') +11),5)).Trim()
    $latencyArray += [double]($metric.Substring(($metric.IndexOf('Latency') +9),5)).Trim()
    $jitterArray += [double]($metric.Substring(($metric.IndexOf('Jitter') +8),5)).Trim()
}
Write-Host "`nAverage Call Quality Metrics:`n"
Write-Host "Avg Loss Rate:   $([math]::Round((($lossRateArray | Measure-Object -Average).Average),2))"
Write-Host "Avg Latency:     $([math]::Round((($latencyArray | Measure-Object -Average).Average),2))"
Write-Host "Avg Jitter Rate: $([math]::Round((($jitterArray | Measure-Object -Average).Average),2))"
Write-Host "`nCall Quality Check Has Finished"
$zipPath = $tempFolder + "\TeamsNetAssessmentResults_" + $siteClean + "_" +(Get-Date -Format yyyyMMddHHmmssffff) + ".zip"
$compress = @{
    LiteralPath = (Get-ChildItem -Path $tempFolder).FullName
    CompressionLevel = "Fastest"
    DestinationPath = $zipPath
}
Compress-Archive @compress
Write-Host "`nAll tests complete!" -ForegroundColor Green
Write-Host "`nResults saved to " -ForegroundColor Green -NoNewline
Write-Host "$zipPath"
