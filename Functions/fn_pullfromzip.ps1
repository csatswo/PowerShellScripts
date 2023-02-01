Function PullFromZip {
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true)][string]$FilesToExtract,
        [parameter(Mandatory=$true)][string]$ZipFile
    )
    $f = Get-ChildItem -Path $ZipFile
    Add-Type -AssemblyName "System.IO.Compression.FileSystem"
    $zip = [IO.Compression.ZipFile]::OpenRead($ZipPath)
    $zip.Entries | Where-Object {$_.Name -like "$FilesToExtract"} | ForEach-Object { 
        $fileName = $_.Name
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, "$($f.Directory)\$fileName", $true)
    }
    $zip.Dispose()
}
