<# 
.SYNOPSIS

    Runs the Microsoft Teams Network Assessment tool.
    Adds all resulting files, including the normal console output, to a single ZIP file.
    Duration of the media quality check can be changed, and an output directory for the resulting files can be defined.

.DESCRIPTION

    Runs the Microsoft Teams Network Assessment tool.
    Adds all resulting files, including the normal console output, to a single ZIP file.
    Duration of the media quality check can be changed, and an output directory for the resulting files can be defined.

.PARAMETER Site

    The name of the site being tested. For example: "Los Angeles" or "Site01". Used in naming the resulting files.

.PARAMETER OutputFolder

    The destination directory to copy the results to. Results are also saved to a temp directory.

.PARAMETER Duration

    OPTIONAL [Integer] - The duration in seconds to run the media quality check. The default is 300 seconds.

.PARAMETER Install

    OPTIONAL [Boolean] - True or False. If true, will download and install the Microsoft Teams Network Assessment tool.

.EXAMPLE

    PS> .\Run-MicrosoftTeamsNetworkAssessment -Site Site01
    Runs the test using the existing configuration in NetworkAssessmentTool.exe.config.

.EXAMPLE

    PS> .\Run-MicrosoftTeamsNetworkAssessment -Site Site01 -Duration 3600
    Modifies the NetworkAssessmentTool.exe.config with the provided duration of 1 hour. Modifying the duration may require running from an elevated prompt.

.EXAMPLE

    PS> .\Run-MicrosoftTeamsNetworkAssessmentt -Site Site01 -Duration 60 -Destination "C:\Temp"
    Modifies the NetworkAssessmentTool.exe.config with the provided duration of 1 minute. Modifying the duration may require running from an elevated prompt. Also saves the results to the C:\Temp directory.

.EXAMPLE

    PS> .\Run-MicrosoftTeamsNetworkAssessmentt -Site Site01 -Install $true"
    Downloads and installs NetworkAssessmentTool.exe then runs the test using the default duration.
#>
Param(
    [Parameter(mandatory=$true)][String]$Site,
    [Parameter(Mandatory=$true)][ValidateScript({ if (Test-Path $_){ $true } else { throw "Path $_ is not valid" }})][string]$OutputFolder,
    [Parameter(Mandatory=$false)][ValidateScript({ $_ -gt 0 })][Int]$Duration,
    [Parameter(mandatory=$false)][bool]$Install
)
function InstallTeamsNetAssess {
    Write-Host "Downloading and installing the Microsoft Teams Network Assessment Tool..."
    $downloadPage = Invoke-WebRequest -UseBasicParsing -Uri 'https://www.microsoft.com/en-us/download/confirmation.aspx?id=103017'
    $downloadLink = ($DownloadPage.Links | Where-Object {$_.href -like '*MicrosoftTeamsNetworkAssessmentTool.exe'}).href[0]
    Invoke-WebRequest -UseBasicParsing -Uri $downloadLink -OutFile $tempFolder\MicrosoftTeamsNetworkAssessmentTool.exe
    Write-Warning -Message "The tool will be installed using the default installation path of `'%ProgramFiles(x86)%\Microsoft Teams Network Assessment Tool\`'"
    Start-Process "$tempFolder\MicrosoftTeamsNetworkAssessmentTool.exe" /passive -Wait
    Remove-Item -Path $tempFolder\MicrosoftTeamsNetworkAssessmentTool.exe
}
Function RunAssessment {
    $invalidChars = "[{0}]" -f [regex]::Escape(([IO.Path]::GetInvalidFileNameChars() -join ''))
    $Site = ($Site -replace $invalidChars -replace " ").Trim()
    try {
        $configFile = Get-Content -Path "${env:ProgramFiles(x86)}\Microsoft Teams Network Assessment Tool\NetworkAssessmentTool.exe.config"
        $oldDuration = (($configFile | Where-Object {$_ -like "*MediaDuration*"}) -replace "[^0-9]" , '')
        if ($duration) {
            if ($oldDuration -ne $duration) {
                $i = $configFile.IndexOf(($configFile | Where-Object {$_ -like "*MediaDuration*"}))
                $configFile[$i] = $configFile[$i] -replace '\d+',$duration
                $configFile | Set-Content -Path "${env:ProgramFiles(x86)}\Microsoft Teams Network Assessment Tool\NetworkAssessmentTool.exe.config" -ErrorAction Stop
                Write-Output "`nTest duration changed from [$oldDuration] seconds to [$duration] seconds"
            }
        }
    }
    catch {
        Write-Warning $Error[0].Exception.Message
        Write-Output "Unable to change duration; running for [$oldDuration] seconds. Try running as administrator."
    }
    Write-Output "`nRunning the connectivity check. This may take a few minutes."
    $hostOutput = & "${env:ProgramFiles(x86)}\Microsoft Teams Network Assessment Tool\NetworkAssessmentTool.exe" | Tee-Object ($tempFolder + "\" + (Get-Date -Format yyyyMMddHHmmssffff) + "_service_connectivity_check_terminal.txt")
    $resultsPath = ($hostOutput.Split([System.Environment]::NewLine,[System.StringSplitOptions]::RemoveEmptyEntries)[-1] -split "written to: ")[1]
    Move-Item $resultsPath -Destination $tempFolder
    Write-Output $hostOutput[0..($hostOutput.Count-2)]
    $durationMin = $([math]::Round(((($configFile | Where-Object {$_ -like "*MediaDuration*"}) -replace "[^0-9]" , '') / 60),1))
    Write-Output "`nRunning the media quality check. This will take about [$durationMin] minute(s)."
    $hostOutput = & "${env:ProgramFiles(x86)}\Microsoft Teams Network Assessment Tool\NetworkAssessmentTool.exe" /qualitycheck | Tee-Object ($tempFolder + "\" + (Get-Date -Format yyyyMMddHHmmssffff) + "_quality_check_terminal.txt")
    $resultsPath = ($hostOutput.Split([System.Environment]::NewLine,[System.StringSplitOptions]::RemoveEmptyEntries)[-1] -split "written to: ")[1]
    $results = Import-Csv $resultsPath
    $resultsCsv = ($resultsPath -split "\\")[-1]
    $lossRateArray = @()
    $latencyArray = @()
    $jitterArray = @()
    foreach ($result in $results) {
        $lossRateArray += [double]($result.'LossRate-%')
        $latencyArray += [double]($result.'AverageLatency-Ms')
        $jitterArray += [double]($result.'AverageJitter-Ms')
        $result | Add-Member -NotePropertyName 'Site' -NotePropertyValue $Site
    }
    $results | Export-Csv -Path ($tempFolder + "\" + $resultsCsv) -NoTypeInformation
    Write-Output "`nAverage Call Quality Metrics:`n"
    Write-Output "Avg Loss Rate:   $([math]::Round((($lossRateArray | Measure-Object -Average).Average),2))"
    Write-Output "Avg Latency:     $([math]::Round((($latencyArray | Measure-Object -Average).Average),2))"
    Write-Output "Avg Jitter Rate: $([math]::Round((($jitterArray | Measure-Object -Average).Average),2))"
    Write-Output "`nCall Quality Check Has Finished"
    $zipFileName = ("TeamsNetAssessmentResults_" + $Site + "_" +(Get-Date -Format yyyyMMddHHmmssffff) + ".zip")
    $zipPath = ($OutputFolder + "\" + $zipFileName)
    $compress = @{
        LiteralPath = (Get-ChildItem -Path $tempFolder).FullName
        CompressionLevel = "Fastest"
        DestinationPath = $zipPath
    }
    Compress-Archive @compress
    Write-Output "`nAll tests complete! Results stored at $zipPath"
}
$tempFolder = (New-Item -ItemType Directory -Path ("$env:TEMP" + "\MicrosoftTeamsNetworkAssessmentTool_" + (Get-Date -Format yyyyMMddHHmmssffff))).FullName
if ($Install) {
    InstallTeamsNetAssess
}
if (Test-Path "${env:ProgramFiles(x86)}\Microsoft Teams Network Assessment Tool\NetworkAssessmentTool.exe") {
        Write-Output "Teams Network Assessment Tool found. Running tests."
        RunAssessment
    }
else {
    Write-Output "`n"
    Write-Warning "Teams Network Assessment Tool not found in `'${env:ProgramFiles(x86)}\Microsoft Teams Network Assessment Tool`'. Try running again using the `'-Install `$true`' parameter."
}
