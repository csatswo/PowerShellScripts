﻿Function ConvertTo-MDTable {
    [CmdletBinding()][OutputType([string])]Param (
        [Parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $true)][PSObject[]]$InputObject,
        [Parameter(mandatory=$false)][switch]$HideHeaders
    )
    # Code borrowed from https://www.powershellgallery.com/packages/PSMarkdown/1.1
    # Modified to preserve order of properties, escape special characters, and allow an unpopulated header row
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
        foreach ($item in $InputObject) {
            $items += $item
            foreach ($property in $item.PSObject.Properties) {
                if ($property.Value -ne $null) {
                    $propertyName = $property.Name | EscChar
                    $propertyValue = $property.Value | EscChar
                    if (-not $columns.ContainsKey($property.Name) -or $columns[$property.Name] -lt $propertyValue.ToString().Length) {
                        $columns[$property.Name] = $propertyValue.ToString().Length
                    }
                }
            }
        }
    }
    End {
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
                $value = $value | EscChar
                $values += ('{0,-' + $columns[($property | EscChar)] + '}') -f $value
            }
            ("| " + ($values -join ' | ') + " |")
        }
    }
}
