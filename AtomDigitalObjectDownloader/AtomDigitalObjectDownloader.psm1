using namespace system;
using namespace system.net.http;

Add-Type -AssemblyName 'System.Net'
Add-Type -AssemblyName 'System.Net.Http'

. $PSScriptRoot\SessionManager.ps1
. $PSScriptRoot\CsvDataExtractor.ps1
. $PSScriptRoot\FileSystem.ps1
. $PSScriptRoot\Exception.ps1
. $PSScriptRoot\Downloader.ps1

Function Get-DigitalObjects {
    <#
    .SYNOPSIS

    Batch-download digital objects from AtoM Archive.

    .DESCRIPTION

    Downloads any digital object uploaded to an AtoM archive using a CSV. The CSV should have either
    a digitalObjectURI or digitalObjectPath column containing one or more URIs to digital objects
    existing in AtoM. Ideally, the CSV will be one imported from AtoM itself, so as to be more sure
    that there are no errors with the links.

    .PARAMETER CsvFile

    A path to a CSV file containing either a digitalObjectURI or digitalObjectPath column

    .PARAMETER DestinationFolder

    A path to a folder to download the digital objects into. Uses a folder named 'DigitalObjects'
    in the current folder if this parameter is not specified

    .PARAMETER AtomUrl

    The URL to the AtoM instance to download the objects from

    .PARAMETER Compress

    Compress the digital objects into a zip file after downloading. Deletes the original folder
    after compressing

    .PARAMETER RequireF5Login

    Require the user to enter credentials to an F5 load balancer before attempting to log in to
    AtoM

    .INPUTS

    None. You cannot pipe input to Get-DigitalObjects

    .EXAMPLE

    Download files specified in object.csv from https://myatom.com into the default folder, without
    compressing:

    PS> Get-DigitalObjects -AtomUrl https://myatom.com -CsvFile object.csv

    .EXAMPLE

    Download files specified in object.csv from https://myatom.com into a folder called "OBJ", and
    compress after finishing:

    PS> Get-DigitalObjects -AtomUrl https://myatom.com -CsvFile object.csv -DestinationFolder OBJ -Compress
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Position=0, Mandatory=$True)]
        [ValidateScript({ If (Test-Path $_ -PathType Leaf -ErrorAction SilentlyContinue) {
            $True
        }
        Else {
            Throw "$_ does not exist or is not a file"
        }})]
        [String]
        $CsvFile,

        [Parameter(Mandatory=$False)]
        [String]
        $DestinationFolder,

        [Parameter(Mandatory=$True)]
        [ValidateScript({If ([Uri]::IsWellFormedUriString($_, [UriKind]::Absolute)) {
            $True
        }
        Else {
            Throw "$_ is not a valid URL"
        }})]
        [String]
        $AtomUrl,

        [Switch]
        $Compress,

        [Switch]
        $RequireF5Login
    )

    Try {
        If (-Not $DestinationFolder) {
            $DestinationFolder = 'DigitalObjects'
        }

        [System.Collections.ArrayList] $Uris = GetUrisFromCsv -CsvFile $CsvFile
        Write-Host "Found $($Uris.Count) files to download.`n"

        If ($RequireF5Login) {
            $Session = LoginToF5LoadBalancer -AtomUrl $AtomUrl
            Write-Host
        }
        Else {
            $Session = GetSession -AtomUrl $AtomUrl
        }

        LoginToAtom -AtomUrl $AtomUrl -WebSession $Session
        CreateDestinationFolder $DestinationFolder
        Write-Host "`nStarting Downloads"
        $Result = DownloadFiles -Uris $Uris -DestinationFolder $DestinationFolder -AuthenticatedSession $Session
        $FilesFound = $Result.NumFound
        $NotFound = [System.Collections.ArrayList] $Result.NotFound

        If ($FilesFound -eq 0) {
            Write-Host "`nNone of the file URIs could be downloaded."
        }
        Else {
            If ($NotFound.Count -gt 0) {
                Write-Host "`nThe following file URIs failed to download:" -ForegroundColor Red
                ForEach ($Uri in $NotFound) {
                    Write-Host $Uri -ForegroundColor Red
                }
            }

            If ($Compress) {
                $Archive = CompressFolder -Folder $DestinationFolder
                If ($Archive) {
                    Write-Host "`nFiles were downloaded and compressed to '$Archive'" -ForegroundColor Green
                }
            }
            Else {
                Write-Host "`nFiles were downloaded to '$DestinationFolder'" -ForegroundColor Green
            }
        }
    }
    Catch [HttpRequestException] {
        Write-Host "`nHttp Request Exception:" -ForegroundColor Red
        Write-Host "$_" -ForegroundColor Red
    }
    Catch [DestinationException] {
        Write-Host "`nDestination folder issue:" -ForegroundColor Red
        Write-Host "$_" -ForegroundColor Red
    }
    Catch [LoginException] {
        Write-Host "`nCould not login:" -ForegroundColor Red
        Write-Host "$_" -ForegroundColor Red
    }
    Catch [UriLoadException] {
        Write-Host "`nIssue with loading URIs from CSV:" -ForegroundColor Red
        Write-Host "$_" -ForegroundColor Red
    }
    Catch [System.Management.Automation.RuntimeException] {
        $e = $_.Exception
        $line = $_.InvocationInfo.ScriptLineNumber
        Write-Host "LINE: $line`n$e" -ForegroundColor Red
    }
    Catch {
        Write-Host "$($_.Exception)"
    }
}


Export-ModuleMember -Function 'Get-DigitalObjects'
