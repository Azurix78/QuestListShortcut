[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$releaseSource = Join-Path $PSScriptRoot 'QuestListShortcut'
$tocPath = Join-Path $releaseSource 'QuestListShortcut.toc'
$tocLines = Get-Content -LiteralPath $tocPath -Encoding UTF8
$versionLine = $tocLines | Where-Object { $_ -match '^## Version:\s*' } | Select-Object -First 1
if ($versionLine -notmatch '^## Version:\s*([0-9]+\.[0-9]+\.[0-9]+(?:[-.][A-Za-z0-9]+)*)\s*$') {
    throw 'Version absente ou invalide dans le TOC.'
}
$releaseVersion = $Matches[1]
$payloadFiles = @('QuestListShortcut.toc', 'LICENSE', 'README.md', 'CHANGELOG.md')
$payloadFiles += @($tocLines | Where-Object { $_.Trim() -and -not $_.Trim().StartsWith('#') } | ForEach-Object { $_.Trim() })
$payloadSources = @{}

# Only TOC payload and player-facing documentation enter the public archive.
foreach ($payloadFile in $payloadFiles) {
    if ($payloadFile -notmatch '^[A-Za-z0-9_-]+(?:\.(?:lua|toc|md))?$') {
        throw "Nom de fichier non pris en charge : $payloadFile"
    }
    $payloadRoot = if ($payloadFile -in @('LICENSE', 'CHANGELOG.md')) { $PSScriptRoot } else { $releaseSource }
    $payloadSources[$payloadFile] = Join-Path $payloadRoot $payloadFile
    if (-not (Test-Path -LiteralPath $payloadSources[$payloadFile] -PathType Leaf)) {
        throw "Fichier manquant : $payloadFile"
    }
}

$releaseDirectory = Join-Path $PSScriptRoot 'dist'
[IO.Directory]::CreateDirectory($releaseDirectory) | Out-Null
$releasePath = Join-Path $releaseDirectory "QuestListShortcut-$releaseVersion.zip"
$releaseStream = [IO.File]::Open($releasePath, [IO.FileMode]::Create)
try {
    $releaseZip = New-Object IO.Compression.ZipArchive($releaseStream, [IO.Compression.ZipArchiveMode]::Create, $true)
    try {
        foreach ($payloadFile in $payloadFiles) {
            # Forward slashes make the archive portable across addon managers/OSes.
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $releaseZip, $payloadSources[$payloadFile],
                "QuestListShortcut/$payloadFile", [IO.Compression.CompressionLevel]::Optimal
            ) | Out-Null
        }
    }
    finally { $releaseZip.Dispose() }
}
finally { $releaseStream.Dispose() }
Write-Output "Archive de distribution : $releasePath"
