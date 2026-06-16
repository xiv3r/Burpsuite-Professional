# Shared helpers for Burpsuite-Professional PowerShell installers.
# Dot-sourced by install.ps1.

function Read-NormalizedValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        throw "File not found: $Path"
    }
    $raw = Get-Content -Raw -Path $Path
    return $raw.Trim().ToLower()
}

function Read-BurpVersion {
    [CmdletBinding()]
    param()

    $script:BurpVersion = Read-NormalizedValue -Path 'VERSION'
    if ([string]::IsNullOrWhiteSpace($script:BurpVersion)) {
        throw "VERSION file is empty."
    }
}

function Get-Sha256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        throw "File not found: $Path"
    }
    return (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLower()
}

function Test-Sha256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Expected
    )

    $actual = Get-Sha256 -Path $Path
    if ($actual -ne $Expected.ToLower()) {
        throw "SHA-256 mismatch for ${Path}. Expected $Expected, got $actual."
    }
    Write-Host "SHA-256 verified for $Path"
}

function Invoke-DownloadWithHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [string]$OutFile,

        [Parameter(Mandatory)]
        [string]$ExpectedSha256
    )

    Write-Host "Downloading $OutFile..."
    try {
        Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
    } catch {
        throw "Failed to download ${Url}: $_"
    }

    Test-Sha256 -Path $OutFile -ExpectedSha256 $ExpectedSha256
}

function Test-LoaderHash {
    [CmdletBinding()]
    param()

    $expected = Read-NormalizedValue -Path 'LOADER_SHA256'
    if ([string]::IsNullOrWhiteSpace($expected)) {
        throw "LOADER_SHA256 is empty."
    }
    Test-Sha256 -Path 'loader.jar' -ExpectedSha256 $expected
}
