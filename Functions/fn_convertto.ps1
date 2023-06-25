Function ConvertTo-MDTable {
    [CmdletBinding()]
    [OutputType([string])]
    Param ([Parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $true)][PSObject[]]$InputObject)
    # Code borrowed from https://www.powershellgallery.com/packages/PSMarkdown/1.1
    # Modified to preserve order of properties
    Begin {
        $items   = @()
        $columns = @{}
    }
    Process {
        foreach ($item in $InputObject) {
            $items += $item
            foreach ($property in $item.PSObject.Properties) {
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
            $header += ('{0,-' + $columns[$property] + '}') -f $property
        }
        ("| " + ($header -join ' | ') + " |")
        # Create delimiter row
        $delimiter = @()
        foreach ($property in $headerNames) { $delimiter += '-' * $columns[$property] }
        ("| " + ($delimiter -join ' | ') + " |")
        # Add whitespace to header row for consistent column width throughout table
        foreach ($item in $items) {
            $values = @()
            foreach ($property in $headerNames) {
                $values += ('{0,-' + $columns[$property] + '}') -f $item.($property)
            }
            ("| " + ($values -join ' | ') + " |")
        }
    }
}
