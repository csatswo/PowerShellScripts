# PowerShell Functions
Imported during launch via profile.
```
   Get-ChildItem $importedFunctions\fn_*.ps1 | Foreach-Object {. $_ }
```
