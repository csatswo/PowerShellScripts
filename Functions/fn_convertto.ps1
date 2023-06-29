Function ConvertTo-MDTable {
    [CmdletBinding()]
    [OutputType([string])]
    Param ([Parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $true)][PSObject[]]$InputObject)
    # Code borrowed from https://www.powershellgallery.com/packages/PSMarkdown/1.1
    # Modified to preserve order of properties and escape special characters
    # Lines 16,34,41,49 escape the pipe character in the unlikely event a property name contains one
    # Lines 52-53 escape special characters from property values
    # More escaping may be needed after additional testing
    Begin {
        $items   = @()
        $columns = @{}
    }
    Process {
        foreach ($item in $InputObject) {
            $items += $item
            foreach ($property in $item.PSObject.Properties) {
                $property.Value = ($property.Value -replace '\|','\|')
                if ($property.Value -ne $null) {
                    if (-not $columns.ContainsKey($property.Name) -or $columns[$property.Name] -lt $property.Value.ToString().Length) {
                        $columns[$property.Name] = $property.Value.ToString().Length
                    }
                }
            }
        }
    }
    End {
        $headerNames  = @($item.PSObject.Properties.Name)
        # Get column width sizing
        foreach ($key in $($columns.Keys)) {
            $columns[$key] = [Math]::Max($columns[$key], $key.Length)
        }
        # Add whitespace to header row for consistent column width throughout table
        $header = @()
        foreach ($property in $headerNames) {
            $property = ($property -replace '\|','\|')
            $header += ('{0,-' + $columns[$property] + '}') -f $property
        }
        ("| " + ($header -join ' | ') + " |")
        # Create delimiter row
        $delimiter = @()
        foreach ($property in $headerNames) {
            $property = ($property -replace '\|','\|')
            $delimiter += '-' * $columns[$property]
        }
        ("| " + ($delimiter -join ' | ') + " |")
        # Add whitespace to header row for consistent column width throughout table
        foreach ($item in $items) {
            $values = @()
            foreach ($property in $headerNames) {
                $property = ($property -replace '\|','\|')
                $value = $item.($property)
                $value = ($value -replace '\|','\|')
                $value = ($value -replace '\\\+','\\+')
                $values += ('{0,-' + $columns[$property] + '}') -f $value
            }
            ("| " + ($values -join ' | ') + " |")
        }
    }
}
