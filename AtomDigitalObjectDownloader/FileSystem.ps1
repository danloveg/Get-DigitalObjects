. $PSScriptRoot\Exception.ps1

Function CreateDestinationFolder {
    Param(
        [Parameter(Mandatory=$True)]
        [String]
        $DestinationFolder
    )

    If (Test-Path $DestinationFolder -PathType Container -ErrorAction 'SilentlyContinue') {
        $ItemsInDestination = (Get-ChildItem $DestinationFolder -Force | Measure-Object).Count
        If ($ItemsInDestination -gt 0) {
            $Msg = ("The folder '$DestinationFolder' already exists and has contents. " +
                    "Change to a different folder, or delete the existing folder.")
            Throw [DestinationException]::new($Msg)
        }
    }
    Else {
        New-Item -Path $DestinationFolder -ItemType Directory -Force | Out-Null
    }
}

Function CompressFolder {
    Param(
        [Parameter(Mandatory=$True, Position=0)]
        [String]
        $Folder
    )

    $TrimmedFolder = $Folder.TrimEnd('/').TrimEnd('\')
    $CompressDestination = "$($TrimmedFolder).zip"
    Compress-Archive -Path $Folder -DestinationPath $CompressDestination -Force

    # Ensure archive was created before removing original files
    If (Test-Path $CompressDestination -ErrorAction SilentlyContinue) {
        $ArchiveSize = (Get-Item $CompressDestination).Length
        If ($ArchiveSize -gt 0) {
            Remove-Item -Path $Folder -Recurse -Force
            $CompressDestination
        }
    }
}
