function iseTitle {
    $Host.UI.RawUI.WindowTitle = "M365: $((Get-MsolDomain | Where-Object {$_.isDefault}).name)"
    Set-Location C:\Temp
}