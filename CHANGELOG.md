# Changelog

## 1.3.0

- The global category button now switches to Open all when every category is collapsed, and back to Collapse all when any category is open. Both actions clear the search first.
- Added Normal / Compact text size in the quest log's gear menu. Compact reduces zone names, quest titles and objective text by 20% while preserving the client font.
- Remember the text size across sessions for the account; Normal is the default.
- Localized the new controls in every supported language.
- Added regression tests for expanding categories, saved settings and pooled font restoration. In-game layout and taint validation remain required.

## 1.2.0

- Centralized all UI text in a shared localization module.
- Added German, Spanish (Spain and Latin America), Italian, Brazilian Portuguese, Russian, Korean, Simplified Chinese and Traditional Chinese translations alongside English and French.
- Automatically select the client language and fall back to English for missing translations.
- Localized the description shown in WoW's addon list.
- Added author credit for Syntaxucre, the MIT license and an English user guide.
- Added a distribution package without Windows installers or development files.

## 1.1.0

- Added per-zone tracking controls with empty, partial and fully tracked states.
- Preserved search and collapsed categories during zone tracking actions.

## 1.0.0

- Added Collapse all and Untrack all buttons below the map's quest list.
