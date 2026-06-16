BeforeAll {
    $RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $LibPath = Join-Path $RepoRoot 'lib.ps1'
    . $LibPath
}

Describe 'Read-NormalizedValue' {
    It 'Trims whitespace and lowercases content' {
        $tmp = New-TemporaryFile
        '  ABC123  ' | Set-Content -Path $tmp.FullName -NoNewline
        Read-NormalizedValue -Path $tmp.FullName | Should -Be 'abc123'
        Remove-Item $tmp.FullName
    }

    It 'Throws when file is missing' {
        { Read-NormalizedValue -Path 'definitely-missing-file-12345.txt' } | Should -Throw
    }
}

Describe 'Read-BurpVersion' {
    It 'Reads VERSION and sets $BurpVersion' {
        Push-Location (New-Item -ItemType Directory -Path (Join-Path $env:TEMP ([Guid]::NewGuid().ToString())))
        '2026' | Set-Content -Path 'VERSION' -NoNewline
        Read-BurpVersion
        $BurpVersion | Should -Be '2026'
        Pop-Location
    }

    It 'Throws on empty VERSION' {
        Push-Location (New-Item -ItemType Directory -Path (Join-Path $env:TEMP ([Guid]::NewGuid().ToString())))
        '' | Set-Content -Path 'VERSION' -NoNewline
        { Read-BurpVersion } | Should -Throw
        Pop-Location
    }
}

Describe 'Get-Sha256' {
    It 'Returns lowercase SHA-256 of a file' {
        $tmp = New-TemporaryFile
        'hello world' | Set-Content -Path $tmp.FullName -NoNewline
        Get-Sha256 -Path $tmp.FullName | Should -Be 'b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9'
        Remove-Item $tmp.FullName
    }
}

Describe 'Test-Sha256' {
    It 'Succeeds when hash matches' {
        $tmp = New-TemporaryFile
        'hello world' | Set-Content -Path $tmp.FullName -NoNewline
        { Test-Sha256 -Path $tmp.FullName -ExpectedSha256 'b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9' } | Should -Not -Throw
        Remove-Item $tmp.FullName
    }

    It 'Throws when hash mismatches' {
        $tmp = New-TemporaryFile
        'hello world' | Set-Content -Path $tmp.FullName -NoNewline
        { Test-Sha256 -Path $tmp.FullName -ExpectedSha256 '0000000000000000000000000000000000000000000000000000000000000000' } | Should -Throw
        Remove-Item $tmp.FullName
    }
}
