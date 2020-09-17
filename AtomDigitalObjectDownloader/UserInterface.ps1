Function GetHumanReadableSize {
    Param (
        [Parameter(Mandatory=$true)]
        [int] $Bytes
    )

    $Kilobytes = $Bytes / 1kb
    $Megabytes = $Bytes / 1mb
    $Gigabytes = $Bytes / 1gb

    $HumanReadableSize = ""

    If ($Kilobytes -lt 1) {
        $HumanReadableSize = "{0}.00 B" -f $Bytes
    }
    ElseIf ($Megabytes -lt 1) {
        $HumanReadableSize = "{0:N2} KB" -f $Kilobytes
    }
    ElseIf ($Gigabytes -lt 1) {
        $HumanReadableSize = "{0:N2} MB" -f $Megabytes
    }
    Else {
        $HumanReadableSize = "{0:N2} GB" -f $Gigabytes
    }

    return $HumanReadableSize
}

Function GetLeftNumberPadding {
    Param(
        [Parameter(Mandatory=$True)]
        [int]
        $Count
    )
    If ($Count -eq 0) {
        Return 1
    }
    Return [Math]::Ceiling([Math]::Log10($Count + 1))
}
