$resultsFolder = "C:\TEMP\TestResults"
Get-ChildItem -Path $resultsFolder -Directory | ForEach-Object -pv dir {$_} | ForEach-Object {
    $results = [System.Collections.ArrayList]@()
    Get-ChildItem -Path $dir.FullName -Recurse -Include *.csv | ForEach-Object -pv csv {$_} | ForEach-Object {
        Import-Csv -Path $csv.FullName | ForEach-Object {
            [void]$results.Add($_)
        }
    }
    $results | Export-Csv -Path $($dir.FullName + "\" + $dir.Name + ".csv") -NoTypeInformation
}
