. $PSScriptRoot\FileSystem.ps1

Describe 'File System Unit Tests' -Tag 'Unit' {
    Context 'Create destination folder' {
        Mock New-Item {}

        It 'Should create folder if it does not exist' {
            Mock Test-Path { return $False }
            CreateDestinationFolder 'dummypath'
            Assert-MockCalled New-Item -Times 1 -Scope It
        }

        It 'Should not do anything if folder exists and is empty' {
            Mock Test-Path { return $True }
            Mock Get-ChildItem { return @() }
            CreateDestinationFolder 'dummypath'
            Assert-MockCalled New-Item -Times 0 -Scope It
        }

        It 'Should throw if folder exists and is not empty' {
            Mock Test-Path { return $True }
            Mock Get-ChildItem { return @('existing.file', 'other.file') }
            { CreateDestinationFolder 'dummypath' } | Should -Throw
        }
    }
}

Describe 'File System Integration Tests' -Tag 'Integration' {
    Context 'Create destination folder' {
        It 'Should create folder if it does not exist' {
            $NewFolder = Join-Path -Path $TestDrive -ChildPath 'destination'
            CreateDestinationFolder -DestinationFolder $NewFolder
            Test-Path $NewFolder -ErrorAction SilentlyContinue | Should -BeTrue
        }

        It 'Should not do anything if folder exists and is empty' {
            $NewFolder = Join-Path -Path $TestDrive -ChildPath 'exists'
            New-Item -Path $NewFolder -ItemType Directory
            CreateDestinationFolder -DestinationFolder $NewFolder
            Test-Path $NewFolder -ErrorAction SilentlyContinue | Should -BeTrue
        }

        It 'Should throw if folder exists and is not empty' {
            $NewFolder = Join-Path -Path $TestDrive -ChildPath 'Not Empty'
            New-Item -Path $NewFolder -ItemType Directory
            $File = Join-Path -Path $NewFolder -ChildPath 'file.txt'
            'hello world!' | Out-File -FilePath $File
            { CreateDestinationFolder -DestinationFolder $NewFolder } | Should -Throw
        }
    }
}
