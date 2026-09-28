# QuestListShortcut

<img src="assets/branding/questlistshortcut-curseforge-400.png" alt="QuestListShortcut quest journal logo" width="160" height="160">

Quest-log shortcuts for **World of Warcraft: Forever**, by **Syntaxucre**.

- Collapse every quest category with one click.
- Untrack all quests without abandoning them.
- Track or untrack an entire zone from its header checkbox.
- Automatic client-language selection with English fallback. No addon dependencies or configuration.

Targets Forever **1.60.1 / interface 16001**. Other WoW editions are not supported by this package.

[Player guide](QuestListShortcut/README.md) · [Documentation française](docs/README.fr.md) · [Changelog](CHANGELOG.md) · [MIT license](LICENSE)

## Installation

Extract a distribution ZIP into your Forever client's `Interface/AddOns` directory. The TOC must end up at `Interface/AddOns/QuestListShortcut/QuestListShortcut.toc`.

Restart WoW after the first installation; use `/reload` for updates to a loaded addon. If installing from GitHub's source ZIP, use the release builder below so the license and changelog are included.

## Development

Install a supported Node.js LTS version, then run from the repository root:

```sh
npm install
npm test
```

Node dependencies are development-only and are never included in the addon. The suite checks Lua 5.1 syntax and runs 34 scenarios with simulated WoW APIs, including all translations and the actual TOC loading order. With a standalone Lua interpreter, `lua tests/run.lua` runs the behavior checks directly.

Rendering, translated text layout, combat restrictions and taint still need in-game validation. See the [manual checks](docs/README.fr.md#vérifications-en-jeu). For a bug report, include the addon version, client build and language, reproduction steps and the full Lua error.

## Build a distribution ZIP

On Windows with PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Build-Release.ps1
```

The builder reads the version from `QuestListShortcut/QuestListShortcut.toc` and writes `dist/QuestListShortcut-<version>.zip`. The archive contains one addon folder, its English guide, the root license and changelog. Installers, tests and branding source files are excluded.

Upload that ZIP as a GitHub Release asset or to an addon distribution site. Generated archives belong in `dist/` and are ignored by Git. See the [CurseForge publishing guide](docs/PUBLISHING.fr.md) for project metadata and artwork.

## Repository layout

```text
QuestListShortcut/    Addon Lua files, TOC and player guide
tests/               Lua behavior tests and Node.js runner
docs/                French usage and publishing guides
assets/branding/     Logo exports and generation prompt
LICENSE              Canonical MIT license
CHANGELOG.md         Release history
```

Translations live in `QuestListShortcut/Localization.lua`. Keep translation keys and formatting placeholders consistent and run the tests after editing them. Artwork was generated with imagegen; the original prompt is included in `assets/branding/PROMPT.md`.
