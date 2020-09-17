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

    $Headers = GetNoDuplicateHeaders $CsvFile
    $ImportedCsv = Import-Csv -Path $CsvFile -Delimiter ',' -Encoding 'UTF8' -Header $Headers

    If ($ImportedCsv.Count -lt 2) {
        Throw [UriLoadException]::new('The CSV file is empty')
    }

    # Since we specified the header, the zero-th line is actually the column names
    $FirstLine = $ImportedCsv[1]
    If ($NULL -ne $FirstLine.digitalObjectURI) {
        $DigitalObjectColumn = 'digitalObjectURI'
    }
    ElseIf ($NULL -ne $FirstLine.digitalObjectPath) {
        $DigitalObjectColumn = 'digitalObjectPath'
    }
    Else {
        $Msg = 'Could not find digitalObjectURI or digitalObjectPath column in the CSV'
        Throw [UriLoadException]::new($Msg)
    }

    $LineNumber = 2 # The first line is the column names
    $Uris = [System.Collections.ArrayList]@()
    # Since we specified the header, we have to skip the first row
    ForEach($Line in $ImportedCsv[1..$ImportedCsv.Count]) {
        $UriString = ($Line.$DigitalObjectColumn).Trim()
        If ($UriString) {
            If (-Not [System.Uri]::IsWellFormedUriString($UriString, [System.UriKind]::Absolute)) {
                $Msg = ("Cell '$UriString' in the $DigitalObjectColumn column on line " +
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
        $Msg = "Could not find any URLs in the $DigitalObjectColumn column of the CSV"
        Throw [UriLoadException]::new($Msg)
    }

    $Uris
}

Function GetNoDuplicateHeaders {
    Param(
        [Parameter(Mandatory=$True)]
        [String]
        $CsvFile
    )

    $ResolvedCsv = Resolve-Path $CsvFile
    $FileReader = $Null
    Try {
        [System.Collections.ArrayList] $CleanHeaders = @()
        $FileReader = [System.IO.StreamReader]::new($ResolvedCsv)
        $FirstLine = $FileReader.ReadLine()
        $DirtyHeaders = $FirstLine.Split(',') | ForEach-Object { "$($_.Trim())" } | Where-Object { $_ }

        ForEach ($DirtyHeader in $DirtyHeaders) {
            $HeaderNum = 0
            ForEach ($CleanHeader in $CleanHeaders) {
                If ($CleanHeader -eq $DirtyHeader) {
                    $HeaderNum = [Math]::Max($HeaderNum, 1)
                }
                ElseIf ($CleanHeader -Match $DirtyHeader) {
                    $Match = $CleanHeader -Match '^.+?_(\d+)$'
                    If ($Match) {
                        $MatchingNum = ([Int] $Matches[1]) + 1
                        $HeaderNum = [Math]::Max($HeaderNum, $MatchingNum)
                    }
                }
            }

            If ($HeaderNum -ne 0) {
                $CleanHeaders.Add("$($DirtyHeader)_$($HeaderNum)") | Out-Null
            }
            Else {
                $CleanHeaders.Add($DirtyHeader) | Out-Null
            }
        }

        Return $CleanHeaders.ToArray()
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
