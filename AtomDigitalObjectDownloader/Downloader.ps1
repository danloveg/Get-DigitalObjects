. $PSScriptRoot\UserInterface.ps1
. $PSScriptRoot\SessionManager.ps1

Function DownloadFiles {
    Param(
        [Parameter(Mandatory=$True)]
        [System.Collections.ArrayList]
        $Uris,

        [Parameter(Mandatory=$True)]
        [String]
        $DestinationFolder,

        [Parameter(Mandatory=$True)]
        [Microsoft.PowerShell.Commands.WebRequestSession]
        $AuthenticatedSession
    )

    $OldPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    $PadLeft = GetLeftNumberPadding -Count $Uris.Count
    $Count = 0
    $FilesFound = 0
    $NotFound = [System.Collections.ArrayList] @()
    ForEach ($ObjectUri in $Uris) {
        $Count += 1
        $OutputFileName = $ObjectUri.Segments[$ObjectUri.Segments.Length - 1]
        $OutputFilePath = Join-Path -Path $DestinationFolder -ChildPath $OutputFileName
        $StringCount = ([String] $Count).PadLeft($PadLeft, ' ')
        Write-Host "$StringCount - $OutputFileName " -NoNewline

        Try {
            $Response = Invoke-WebRequest -Uri $ObjectUri -WebSession $AuthenticatedSession -OutFile $OutputFilePath
        }
        Catch {
            If ($Response -or $_.Exception.Response) {
                If (-Not $Response) {
                    $Response = $_.Exception.Response
                }
                $Result = ExtractStatusCodeAndDescription -Response $Response
                $Description = ([String] $Result.Description).ToUpper()
                Write-Host "($($Result.Code) $Description)" -ForegroundColor Red
            }
            Else {
                Write-Host "($($_.Exception.Message))" -ForegroundColor Red
            }
            $NotFound.Add([String] $ObjectUri) | Out-Null
            Continue
        }

        $FileLength = GetHumanReadableSize -Bytes (Get-Item $OutputFilePath).Length
        Write-Host "($FileLength)"
        $FilesFound += 1
    }
    $ProgressPreference = $OldPreference

    Return [PsCustomObject] @{
        NumFound=$FilesFound;
        NotFound=$NotFound;
    }
}
