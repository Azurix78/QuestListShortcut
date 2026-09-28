# QuestListShortcut

Des raccourcis en bas de la liste des quêtes et une case de suivi par zone, pour **WoW Forever 1.60.1** (interface **16001**, client cible **70009**). Version de l'addon : **1.2.0**, par **Syntaxucre**, sous [licence MIT](../LICENSE).

- **Tout replier** efface la recherche puis replie toutes les catégories. Tu peux ensuite les rouvrir individuellement.
- **Arrêter le suivi** retire immédiatement toutes les quêtes suivies, même masquées par une recherche ou une catégorie repliée. Les quêtes restent dans le journal. Le réglage de suivi automatique du jeu reste inchangé : le jeu peut donc suivre de nouveau une quête par la suite.

Les boutons utilisent le style Blizzard et la langue du client. Une bande de 32 pixels d'interface est réservée sous la liste. Les raccourcis disparaissent dans les détails d'une quête. Une action indisponible est grisée, avec la raison dans son infobulle.

Aucun réglage, commande slash, dépendance externe ou donnée sauvegardée.

## Langues

Tous les libellés, infobulles, compteurs et messages de l'addon sont centralisés dans `QuestListShortcut/Localization.lua`. La langue est choisie automatiquement via `GetLocale()` au chargement.

| Client | Traduction |
| --- | --- |
| `enUS`, `enGB` | Anglais |
| `frFR` | Français |
| `deDE` | Allemand |
| `esES`, `esMX` | Espagnol commun aux deux régions |
| `itIT` | Italien |
| `ptBR` | Portugais brésilien |
| `ruRU` | Russe |
| `koKR` | Coréen |
| `zhCN` | Chinois simplifié |
| `zhTW` | Chinois traditionnel |

Une clé manquante ou une langue inconnue utilise l'anglais. La description affichée dans la liste des addons est également traduite. Aucun service externe ni bibliothèque de traduction n'est nécessaire.

Pour corriger une traduction, modifier uniquement les valeurs du bloc correspondant dans `Localization.lua`, en conservant les clés et les deux `%d` du compteur. Pour ajouter un texte, le définir d'abord dans la table anglaise, puis dans chaque traduction, et relancer les tests. Les traductions sont complètes dans le code ; leur terminologie et leur rendu doivent encore être relus dans les clients concernés.

## Distribution

La version destinée aux sites et gestionnaires d'addons se génère avec :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Build-Release.ps1
```

L'archive **dist/QuestListShortcut-1.2.0.zip** contient un unique dossier `QuestListShortcut/`, sans installateur Windows ni tests. Le nom de la prochaine archive sera déterminé par `## Version` dans le TOC.

Le [guide de publication CurseForge](PUBLISHING.fr.md) fournit le résumé anglais, les métadonnées et les vérifications restantes. Le [guide anglais pour les joueurs](../QuestListShortcut/README.md), le changelog et la licence MIT sont inclus dans l'archive. Les scripts d'installation Windows restent disponibles dans ce projet pour ton installation locale.

## Suivi par zone

Chaque en-tête de zone possède une petite case à droite, à côté du bouton de repli :

- **Case vide** : aucune quête de la zone suivie. Cliquer pour **Suivre tout**.
- **Tiret doré** : certaines quêtes sont suivies. Cliquer pour compléter le suivi de toute la zone.
- **Case cochée** : toutes les quêtes sont suivies. Cliquer pour **Effacer le suivi** de cette zone.

L'infobulle indique l'action et le nombre de quêtes suivies. Le clic concerne toutes les quêtes de la catégorie, y compris lorsqu'elle est repliée ou que certaines quêtes sont masquées par une recherche. La recherche et l'état replié sont conservés ; les autres zones restent inchangées. Les quêtes internes cachées par le jeu et les tâches ne sont pas ajoutées au suivi.

Le bouton `+` / `−` reste indépendant. Les deux contrôles sont placés à l'intérieur de l'en-tête pour rester accessibles dans la zone défilante. En cas de limite de suivi ou de restriction du jeu, la case reflète le résultat réel et un message signale une opération incomplète.

## Installation

### Installation automatique (Windows)

Double-cliquer sur [Installer-Addon.cmd](../Installer-Addon.cmd). Ce lanceur exécute [Install-Addon.ps1](../Install-Addon.ps1), qui copie l'addon dans `C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\QuestListShortcut`.

Le script remplace les fichiers de l'addon lors des mises à jour et conserve les autres addons ainsi que le dossier `WTF`. Si Windows refuse l'accès, faire un clic droit sur le lanceur puis **Exécuter en tant qu'administrateur**.

Depuis PowerShell, à la racine du projet :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install-Addon.ps1
# Simuler sans rien copier :
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install-Addon.ps1 -WhatIf
# Choisir une autre installation de WoW :
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install-Addon.ps1 -AddOnsPath 'D:\World of Warcraft\_classic_beta_\Interface\AddOns'
```

Après une première installation, relancer WoW et activer **QuestListShortcut** dans la liste des addons. Pour une mise à jour de l'addon déjà chargé, utiliser `/reload`.

### Installation manuelle

Depuis les sources GitHub, générer d'abord l'archive avec `Build-Release.ps1` pour inclure la licence et le changelog. Les étapes suivantes s'appliquent au contenu de cette archive.

1. Copier le sous-dossier **QuestListShortcut** de ce projet dans :

   `C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\`

2. Vérifier que le fichier se trouve directement à cet emplacement :

   `Interface\AddOns\QuestListShortcut\QuestListShortcut.toc`

3. Pour la première installation, relancer WoW et activer **QuestListShortcut** dans la liste des addons. Pour une mise à jour de l'addon déjà chargé, utiliser `/reload`.
4. Ouvrir **Carte & journal des quêtes** : les deux boutons sont au bas du panneau de droite.

Le dossier livré est prêt à copier ; lancer l'installateur ou effectuer la copie manuelle pour l'ajouter au jeu.

## Vérifications en jeu

La validation hors jeu ne peut pas garantir le rendu, l'absence de taint ou les restrictions de cette bêta. La compatibilité du build 70009 reste à confirmer dans le client.

- Mélanger des catégories ouvertes et fermées, puis cliquer sur **Tout replier** : toutes doivent se fermer. Répéter le clic, puis rouvrir manuellement une catégorie.
- Lancer une recherche, puis replier : la recherche doit être effacée et toutes les catégories fermées.
- Suivre plusieurs quêtes réparties dans plusieurs catégories, en masquer par recherche, puis arrêter le suivi : aucune quête ne doit rester suivie et le nombre de quêtes du journal doit rester identique.
- Répéter avec une seule quête suivie, aucune quête suivie et un journal vide. Les actions sans cible doivent être grisées.
- Tester une longue liste défilante, notamment sa dernière ligne, en carte réduite et agrandie, puis à plusieurs échelles d'interface. Rien ne doit être recouvert par les boutons.
- Ouvrir une quête, revenir à la liste, fermer et rouvrir la carte, puis faire `/reload` : aucun doublon ni décalage progressif des boutons.
- Tester hors combat et en combat ; si le jeu interdit le retrait du suivi, le bouton doit être grisé et l'infobulle doit l'expliquer.
- Vérifier BugSack après ces actions. En cas de problème, conserver le texte complet de l'erreur, le build du client et l'action effectuée.
- Dans une zone avec plusieurs quêtes, cliquer sur sa case : tout suivre, puis tout désuivre. Vérifier qu'une quête suivie dans une autre zone le reste.
- Suivre une seule quête de cette zone : la case affiche un tiret ; cliquer complète le suivi. Refaire le test avec la zone repliée et avec une recherche active.
- Accepter ou terminer une quête, changer de carte et modifier le suivi individuellement : les cases doivent se mettre à jour sans doublon ni action sur une autre zone.
- Vérifier les longs noms de zones, la dernière catégorie de la liste et les clics distincts sur la case et sur `+` / `−`, à plusieurs échelles d'interface.

Le jeu conserve ses comportements natifs : changer de carte ou survoler un marqueur peut rouvrir une catégorie. L'addon ne force pas leur fermeture après le clic.

## Développement

Validation effectuée : syntaxe Lua 5.1 vérifiée avec `luaparse`, et **34 scénarios simulés réussis** avec Fengari. Ces tests couvrent les indices qui changent pendant les opérations, la recherche, les restrictions natives, les API absentes, le chargement différé, la visibilité, les ancrages répétés, le suivi par zone, les états partiels, les limites de suivi et la réutilisation des en-têtes. Les tests de langues vérifient les 12 codes de client ci-dessus, les clés complètes, les marqueurs de formatage, les libellés et les infobulles, le retour à l'anglais et le chargement réel dans l'ordre du TOC. Aucun essai visuel ou fonctionnel n'a encore été effectué dans WoW.

Les actions globales sont dans `QuestListShortcut/Core.lua`, et le suivi par zone dans `QuestListShortcut/ZoneTracking.lua`. `Localization.lua` est chargé en premier et partage ses textes via la table privée de l'addon fournie par WoW. Les tests de régression utilisent des API WoW simulées, sans accès au jeu. Depuis la racine, lancer `npm install` puis `npm test`, ou `lua tests/run.lua` avec Lua 5.1 ou ultérieur. Les dépendances Node.js sont uniquement utilisées pour le développement.

Références consultées : [panneau Forever (Lua)](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/QuestMapFrame.lua), [ancrages du panneau (XML)](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/QuestMapFrame.xml), [API du journal](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua).
