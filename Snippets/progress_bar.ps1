# progress_bar.ps1
# Displays a progress bar while looping through an array

$i = 0; foreach ($thing in $array) {
    $i++; $percentComplete = [int](($i / $array.Count) * 100)
    Write-Progress -Activity "Processing thing: $($thing.SpecifcProperty)" -Status "$percentComplete% Complete:" -PercentComplete $percentComplete
}
