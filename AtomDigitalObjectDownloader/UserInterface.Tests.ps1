. $PSScriptRoot\UserInterface.ps1

Describe 'User Interface Unit Tests' -Tag 'Unit' {
    Context 'Get human readable size' {
        It 'Does not convert 0 bytes' {
            GetHumanReadableSize -Bytes 0 | Should -BeExactly '0.00 B'
        }
        It 'Converts 1024 bytes to 1 kilobyte' {
            GetHumanReadableSize -Bytes 1024 | Should -BeExactly '1.00 KB'
        }
        It 'Converts 1048576 bytes to 1 megabyte' {
            GetHumanReadableSize -Bytes 1048576 | Should -BeExactly '1.00 MB'
        }
        It 'Converts 1073741824 bytes to 1 gigabyte' {
            GetHumanReadableSize -Bytes 1073741824 | Should -BeExactly '1.00 GB'
        }
    }

    Context 'Get left number padding' {
        It 'Returns 1 if count is zero' {
            GetLeftNumberPadding -Count 0 | Should -BeExactly 1
        }
        It 'Returns 1 if only one digit' {
            GetLeftNumberPadding -Count 9 | Should -BeExactly 1
        }
        It 'Returns 2 if two digits' {
            GetLeftNumberPadding -Count 99 | Should -BeExactly 2
        }
        It 'Returns 3 if three digits' {
            GetLeftNumberPadding -Count 999 | Should -BeExactly 3
        }
        It 'Returns 4 if four digits' {
            GetLeftNumberPadding -Count 9999 | Should -BeExactly 4
        }
    }
}
