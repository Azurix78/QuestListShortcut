# Préparer la publication

## Fichier à déposer

Lancer `powershell -NoProfile -ExecutionPolicy Bypass -File .\Build-Release.ps1` depuis le projet. Déposer **dist/QuestListShortcut-1.2.0.zip** : elle contient uniquement le dossier `QuestListShortcut/`, avec les fichiers de l'addon, le guide anglais, le changelog et la licence MIT.

Les anciennes archives 1.0.0 et 1.1.0, conservées localement dans `dist/archive/` et exclues de Git, contiennent l'installateur Windows. Utiliser la nouvelle archive de `dist` pour les sites et gestionnaires d'addons.

## Fiche du projet

- Nom : **QuestListShortcut**.
- Auteur : **Syntaxucre**.
- Licence : **MIT** (le texte est inclus dans l'addon).
- Jeu : **World of Warcraft** ; sélectionner **Forever / 1.60.1** dans les choix proposés. Ne pas annoncer de compatibilité Retail, Classic Era ou autres éditions sans tests.
- Catégorie suggérée : **Quests & Leveling**, si proposée dans le formulaire.
- Description anglaise : reprendre le [guide destiné aux joueurs](../QuestListShortcut/README.md). Ajouter ensuite une version française si souhaité.
- Résumé anglais : **Collapse quest categories and manage quest tracking globally or by zone in WoW Forever.**
- Changelog : reprendre la section 1.2.0 de [CHANGELOG.md](../CHANGELOG.md).
- Icône : utiliser [questlistshortcut-curseforge-400.png](../assets/branding/questlistshortcut-curseforge-400.png), au format PNG de 400 × 400 pixels. L'original et le prompt de génération sont dans `assets/branding/`. Ajouter également un moyen de signaler les bugs.

Choisir un type de fichier adapté à la validation effectuée : commencer en **Beta** tant que les tests en jeu ne sont pas terminés. CurseForge indique qu'au moins un fichier **Release** est nécessaire pour la synchronisation normale du projet avec son application.

## Vérifications avant dépôt

- Réinstaller la version 1.2.0 et tester les boutons globaux et par zone, carte réduite/agrandie, rechargement et combat ; consulter BugSack.
- Vérifier le rendu des textes sur les clients disponibles, notamment les boutons en allemand, portugais et russe, et les polices des clients asiatiques.
- Les textes traduits sont fournis, mais leur terminologie et leur rendu n'ont pas été relus dans chaque client. Inviter les utilisateurs à proposer des corrections.
- L'archive est préparée localement. Aucun projet n'a été créé ou publié sur CurseForge.

Les traductions sont embarquées dans `Localization.lua` ; elles ne dépendent pas du système de traduction en ligne de CurseForge. Celui-ci peut être utilisé plus tard pour recueillir des contributions.

Sources officielles consultées : [création et dépôt](https://support.curseforge.com/support/solutions/articles/9000197241), [règles de modération, descriptions et icônes](https://support.curseforge.com/support/solutions/articles/9000197279), [traductions communautaires](https://support.curseforge.com/support/solutions/articles/9000197356-project-localization).
