$resultsFolder = "C:\TEMP\TestResults"
Get-ChildItem -Path $resultsFolder -Directory | foreach -pv dir {$_} | foreach {
    $results = [System.Collections.ArrayList]@()
    Get-ChildItem -Path $dir.FullName -Recurse -Include *.csv | foreach -pv csv {$_} | foreach {
        Import-Csv -Path $csv.FullName | foreach {
            [void]$results.Add($_)
        }
    }
    $results | Export-Csv -Path $($dir.FullName + "\" + $dir.Name + ".csv") -NoTypeInformation
}
