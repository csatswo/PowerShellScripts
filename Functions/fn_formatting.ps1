Function Set-ISETitle {
    Param ([Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)][String]$Title)
    $Host.UI.RawUI.WindowTitle = $Title
}

New-Alias -Name fm -Value Format-Markdown -Description 'fm -> Format-Markdown'
Function Format-Markdown {
    [CmdletBinding()][OutputType([string])]Param (
        [Parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $true)][PSObject[]]$InputObject,
        [Parameter(mandatory=$false)][switch]$HideHeaders
    )
    # Code borrowed from https://www.powershellgallery.com/packages/PSMarkdown/1.1
    # Modified to preserve order of properties, escape special characters, support null values, and allow an unpopulated header row
    # More escaping may be needed after additional testing
    Begin {
        $items   = @()
        $columns = @{}
        Function EscChar {
            [CmdletBinding()][OutputType([string])]Param([Parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $true)]$Chars)
            $Chars = $Chars -replace '\|','\|'
            $Chars = $Chars -replace '\+','\+'
            $Chars
        }
    }
    Process {
        if ($InputObject) {
            foreach ($item in $InputObject) {
                $items += $item
                foreach ($property in $item.PSObject.Properties) {
                    if ($null -ne $property.Value) {
                        $propertyName = $property.Name | EscChar
                        $propertyValue = $property.Value | EscChar
                    }
                    if (-not $columns.ContainsKey($property.Name) -or $columns[$property.Name] -lt $propertyValue.ToString().Length) {
                        $columns[$property.Name] = $propertyValue.ToString().Length
                    }
                }
            }
        }
    }
    End {
        if ($InputObject) {
            $headerNames = @($item.PSObject.Properties.Name)
            # Get column width sizing
            foreach ($key in $($columns.Keys)) {
                $columns[$key] = [Math]::Max($columns[$key], $key.Length)
            }
            # Add whitespace to header row for consistent column width throughout table
            $header = @()
            foreach ($property in $headerNames) {
                $fproperty = $property | EscChar
                if ($HideHeaders) {$fproperty = ($fproperty -replace '.',' ')}
                $header += (('{0,-' + $columns[$property] + '}') -f $fproperty)
            }
            ("| " + ($header -join ' | ') + " |")
            # Create delimiter row
            $delimiter = @()
            foreach ($property in $headerNames) {
                # $property = $property | EscChar
                $delimiter += '-' * $columns[$property]
            }
            ("| " + ($delimiter -join ' | ') + " |")
            # Add whitespace to header row for consistent column width throughout table
            foreach ($item in $items) {
                $values = @()
                foreach ($property in $item.PSObject.Properties.Name) {
                    # $property = $property | EscChar
                    $value = $item.($property)
                    if ($null -ne $value ) {
                        $value = $value | EscChar
                    }
                    $values += ('{0,-' + $columns[($property | EscChar)] + '}') -f $value
                }
                ("| " + ($values -join ' | ') + " |")
            }
        }
    }
}

Function ConvertFrom-Base64($Base64) {
    return [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($Base64))
}

Function ConvertTo-Base64($String) {
    return [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($String))
}
