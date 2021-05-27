. $PSScriptRoot\Exception.ps1

Function GetUrisFromCsv {
    Param(
        [Parameter(Mandatory=$True)]
        [ValidateScript({ If (Test-Path $_ -PathType Leaf -ErrorAction SilentlyContinue) {
            $True
        } Else {
            Throw [UriLoadException]::new("$_ does not exist or is not a file")
        }})]
        [String]
        $CsvFile
    )

    CheckForDuplicateHeaders $CsvFile
    $ImportedCsv = Import-Csv -Path $CsvFile -Delimiter ',' -Encoding 'UTF8'
    $LineNumber = 2
    $Uris = [System.Collections.ArrayList] @()
    ForEach($Line in $ImportedCsv) {
        $UriString = ($Line.'digitalObjectURI').Trim()
        If ($UriString) {
            If (-Not [System.Uri]::IsWellFormedUriString($UriString, [System.UriKind]::Absolute)) {
                $Msg = ("Cell '$UriString' in the digitalObjectURI column on line " +
                        "$LineNumber of the CSV is not a valid URI")
                Throw [UriLoadException]::new($Msg)
            }

            $NewUri = [System.Uri] $UriString

            If ($NewUri.Segments.Length -lt 2) {
                $Msg = "URI on line $($LineNumber) does not appear to point to a file"
                Throw [UriLoadException]::new($Msg)
            }

            $Uris.Add($NewUri) | Out-Null
        }
        $LineNumber += 1
    }

    If ($Uris.Count -eq 0) {
        $Msg = "Could not find any URLs in the digitalObjectURI column of the CSV"
        Throw [UriLoadException]::new($Msg)
    }

    $Uris
}

Function CheckForDuplicateHeaders {
    Param(
        [Parameter(Mandatory=$True)]
        [String]
        $CsvFile
    )

    $ResolvedCsv = Resolve-Path $CsvFile
    $FileReader = $Null
    Try {
        $FileReader = [System.IO.StreamReader]::new($ResolvedCsv)
        $FirstLine = $FileReader.ReadLine()
        $DirtyHeaders = $FirstLine.Split(',') | ForEach-Object { "$($_.Trim())" } | Where-Object { $_ }
        $GroupedHeaders = $DirtyHeaders | Group-Object
        ForEach($Group in $GroupedHeaders) {
            If ($Group.Count -gt 1) {
                $Msg = "The column name '$($Group.Name)' appears more than once"
                Throw [CsvReadException]::new($Msg)
            }
        }
    }
    Catch [Exception] {
        Throw $_
    }
    Finally {
        If ($Null -ne $FileReader) {
            $FileReader.Close()
            $FileReader = $Null
        }
    }
}
