function iseTitle {
    $Host.UI.RawUI.WindowTitle = (Get-MsolDomain | Where-Object {$_.isDefault}).name
    Set-Location C:\Temp
}