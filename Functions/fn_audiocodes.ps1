Function AudioCodesUtils {
    $audcURL = 'http://redirect.audiocodes.com/install'
    $audcIndexPage = Invoke-WebRequest -UseBasicParsing -Uri ($audcURL + '/index.html')
    $downloadLinks = ($audcIndexPage.Links | Where-Object {$_.href -like '*syslogViewer-setup.exe' -or $_.href -like '*iniedit-setup.exe' -or $_.href -like '*sbcwizard-setup.exe'}).href
    foreach ($link in $downloadLinks) {
        ($link -split '/')[1]
        $outFile = "$pwd\$(($link -split '/')[1])"
        Invoke-WebRequest -UseBasicParsing -Uri ($audcURL + '/' + $link) -OutFile $outFile
    }
}
