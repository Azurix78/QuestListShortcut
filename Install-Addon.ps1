[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateNotNullOrEmpty()]
    [string]$AddOnsPath = 'C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns'
)

$ErrorActionPreference = 'Stop'

try {
    $addonSource = Join-Path $PSScriptRoot 'QuestListShortcut'
    foreach ($requiredFile in @('QuestListShortcut.toc', 'Localization.lua', 'Core.lua', 'ZoneTracking.lua')) {
        if (-not (Test-Path -LiteralPath (Join-Path $addonSource $requiredFile) -PathType Leaf)) {
            throw "Fichier source introuvable : QuestListShortcut\$requiredFile. Gardez le dossier de l addon a cote du script."
        }
    }
    foreach ($document in @('LICENSE', 'CHANGELOG.md')) {
        if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $document) -PathType Leaf)) {
            throw "Document source introuvable : $document"
        }
    }
    if (-not (Test-Path -LiteralPath $AddOnsPath -PathType Container)) {
        throw "Dossier AddOns introuvable : $AddOnsPath"
    }

    $addonDestination = Join-Path (Resolve-Path -LiteralPath $AddOnsPath).ProviderPath 'QuestListShortcut'
    if ([string]::Equals([IO.Path]::GetFullPath($addonSource), [IO.Path]::GetFullPath($addonDestination), [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Le dossier source est deja le dossier de destination.'
    }

    if ($PSCmdlet.ShouldProcess($addonDestination, 'Installer ou mettre a jour QuestListShortcut')) {
        [IO.Directory]::CreateDirectory($addonDestination) | Out-Null
        Get-ChildItem -LiteralPath $addonSource | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination $addonDestination -Recurse -Force
        }
        foreach ($document in @('LICENSE', 'CHANGELOG.md')) {
            Copy-Item -LiteralPath (Join-Path $PSScriptRoot $document) -Destination $addonDestination -Force
        }
        Write-Host "QuestListShortcut installe dans : $addonDestination" -ForegroundColor Green
        Write-Host 'Premiere installation : relancez WoW et activez QuestListShortcut dans la liste des addons.'
        Write-Host 'Mise a jour d un addon deja charge : tapez /reload en jeu.'
    }
}
catch {
    Write-Host "Installation impossible : $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Si Windows refuse l acces, faites un clic droit sur Installer-Addon.cmd puis Executer en tant qu administrateur.'
    exit 1
}
