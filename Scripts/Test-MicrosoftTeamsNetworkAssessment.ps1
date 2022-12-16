<# 
.SYNOPSIS

    Downloads, installs, and runs the Microsoft Teams Network Assessment tool.
    Adds all resulting files, including the normal console output, to a single ZIP file.
    Duration of the media quality check can be changed, and an output directory for the resulting files can be defined.

.DESCRIPTION

    Downloads, installs, and runs the Microsoft Teams Network Assessment tool.
    Adds all resulting files, including the normal console output, to a single ZIP file.
    Duration of the media quality check can be changed, and an output directory for the resulting files can be defined.

.PARAMETER Site

    The name of the site being tested. For example: "Los Angeles" or "Site01". Used in naming the resulting files.

.PARAMETER Duration

    OPTIONAL - The duration in seconds to run the media quality check. The default is 300 seconds.

.PARAMETER Destination

    OPTIONAL - The destination directory to copy the results to. Results are saved to temp directory regardless.

.EXAMPLE

    PS> .\Test-MicrosoftTeamsNetworkAssessment -Site Site01
    Runs the test using the existing configuration in NetworkAssessmentTool.exe.config.

.EXAMPLE

    PS> .\Test-MicrosoftTeamsNetworkAssessment -Site Site01 -Duration 3600
    Modifies the NetworkAssessmentTool.exe.config with the provided duration of 1 hour.

.EXAMPLE

    PS> .\Test-MicrosoftTeamsNetworkAssessment -Site Site01 -Duration 60 -Destination "C:\Temp"
    Modifies the NetworkAssessmentTool.exe.config with the provided duration of 1 minute. Also saves the results to the C:\Temp directory.
#>
Param(
    [Parameter(mandatory=$true)][String]$Site,
    [Parameter(Mandatory = $false)][ValidateScript({
        $_ -gt 0
    })][Int]$Duration,
    [Parameter(Mandatory = $false)][ValidateScript({
        if (Test-Path $_){
            $true
        } else {
            throw "Path $_ is not valid"
        }})][string]$Destination 
)
$invalidChars = "[{0}]" -f [regex]::Escape(([IO.Path]::GetInvalidFileNameChars() -join ''))
$Site = ($Site -replace $invalidChars -replace " ").Trim()
$downloadPage = Invoke-WebRequest -UseBasicParsing -Uri 'https://www.microsoft.com/en-us/download/confirmation.aspx?id=103017'
$downloadLink = ($DownloadPage.Links | Where-Object {$_.href -like '*MicrosoftTeamsNetworkAssessmentTool.exe'}).href[0]
$tempFolder = (New-Item -ItemType Directory -Path ("$env:TEMP" + "\MicrosoftTeamsNetworkAssessmentTool_" + (Get-Date -Format yyyyMMddHHmmssffff))).FullName
Write-Host "`nDownloading the Microsoft Teams Network Assessment Tool..." -ForegroundColor Cyan
Invoke-WebRequest -UseBasicParsing -Uri $downloadLink -OutFile $tempFolder\MicrosoftTeamsNetworkAssessmentTool.exe
Write-Warning -Message "The tool will be installed using the default installation path of `'%ProgramFiles(x86)%\Microsoft Teams Network Assessment Tool\`'"
Write-Host "`nInstalling the Microsoft Teams Network Assessment Tool..." -ForegroundColor Cyan
Start-Process "$tempFolder\MicrosoftTeamsNetworkAssessmentTool.exe" /passive -Wait
$configFile = Get-Content -Path "${env:ProgramFiles(x86)}\Microsoft Teams Network Assessment Tool\NetworkAssessmentTool.exe.config"
Write-Host "`nRunning the connectivity check. This may take a few minutes." -ForegroundColor Cyan
$hostOutput = & "${env:ProgramFiles(x86)}\Microsoft Teams Network Assessment Tool\NetworkAssessmentTool.exe" | Tee-Object ($tempFolder + "\" + (Get-Date -Format yyyyMMddHHmmssffff) + "_service_connectivity_check_terminal.txt")
$startIndex = ($hostOutput[$hostOutput.Count-1]).indexof('C:\')
$length = (($hostOutput[$hostOutput.Count-1]).Length) - $startIndex
$result = ($hostOutput[$hostOutput.Count-1]).Substring($startIndex,$length)
Move-Item $result -Destination $tempFolder
Write-Host `n
$hostOutput[0..($hostOutput.Count-2)]
if ($duration) {
        if ($duration -le 300) {
        # Write-Host "`nThe duration of the quality check will be $duration seconds. The default is 300 seconds." -ForegroundColor Yellow
    } else {
        # Write-Host "`nThe duration of the quality check will be $duration seconds. The default is 300 seconds." -ForegroundColor Yellow
        # Maybe add confirmation? Output warning to use Ctrl+C to abort?
    }
    $oldDuration = (($configFile | Where-Object {$_ -like "*MediaDuration*"}) -replace "[^0-9]" , '')
    Write-Host "`nUpdating configuration - changing test duration from $oldDuration to $duration"
    $i = $configFile.IndexOf(($configFile | Where-Object {$_ -like "*MediaDuration*"}))
    $configFile[$i] = $configFile[$i] -replace '\d+',$duration
    $configFile | Set-Content -Path "${env:ProgramFiles(x86)}\Microsoft Teams Network Assessment Tool\NetworkAssessmentTool.exe.config"
}
$durationMin = $([math]::Round(((($configFile | Where-Object {$_ -like "*MediaDuration*"}) -replace "[^0-9]" , '') / 60),1))
Write-Host "`nRunning the connectivity check. This will take about $durationMin minute(s)." -ForegroundColor Cyan
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
Remove-Item -Path $tempFolder\MicrosoftTeamsNetworkAssessmentTool.exe
$zipFileName = ("TeamsNetAssessmentResults_" + $Site + "_" +(Get-Date -Format yyyyMMddHHmmssffff) + ".zip")
$zipPath = ($tempFolder + "\" + $zipFileName)
$compress = @{
    LiteralPath = (Get-ChildItem -Path $tempFolder).FullName
    CompressionLevel = "Fastest"
    DestinationPath = $zipPath
}
Compress-Archive @compress
Write-Host "`nAll tests complete!" -ForegroundColor Green
if ($Destination ) {
    Write-Host "`nCopying results to $Destination"
    try {
        Copy-Item -Path $zipPath -Destination $Destination -ErrorAction Stop
        Write-Host "Results saved to $Destination`n" -ForegroundColor Green
    } catch {
        Write-Host "`nError: $($Error[0])" -ForegroundColor Red
        Write-Host "Results saved to $zipPath`n"
    }
} else {
    Write-Host "Results saved to $zipPath`n"
}
