# Time a command and show in seconds
Function TimeCommand($command) {
    Write-Output "Command execution took $((Measure-Command -Expression { &$command }).TotalSeconds) seconds"
}
# Time a command and show in milliseconds
Function TimeCommandMS($command) {
    Write-Output "Command execution took $((Measure-Command -Expression { &$command }).TotalMilliseconds) milliseconds"
}
<#
Function  TimeCommandOld {
    $cmd = ""
    for ($i = 0; $i -lt $args.Count; $i++) {
        $cmd += $args[$i]
        if ($i -lt $args.Count -1) {
            $cmd += " "
        }
    }
    $start = Get-Date
    Invoke-Expression -Command $cmd
    $duration = (Get-Date) - $start
    Write-Host "Command execution took $($duration.TotalSeconds) seconds" -ForegroundColor Yellow
}
#>
