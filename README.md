# Corbuilder : dossier des versions

Ce dossier est un petit « serveur de versions » statique : rien à installer, juste des fichiers servis en HTTPS.
Le menu **Versions** du thème Corbuilder (Apparence → Versions, réservé aux administrateurs) lit `versions.json`,
affiche les versions disponibles et installe celle qu'on choisit, en remplaçant la version actuelle.

> Le menu « Versions » du thème n'est pas encore écrit : ce dossier est prêt, mais les sites ne le liront qu'une fois
> le thème livré avec ce menu (à installer une première fois à la main).

## Contenu

```
corbuilder-versions/
  versions.json            liste des versions (généré, ne pas modifier à la main)
  build-versions.sh        script qui génère versions.json
  corbuilder-2.3.2.zip     une version du thème par fichier, nommée corbuilder-x.y.z.zip
  corbuilder-2.4.0.zip
  notes/2.4.0.txt          notes de version, facultatives (une note par ligne)
  .nojekyll                fichier vide, utile seulement pour GitHub Pages
```

Tout est en liens **relatifs** : on peut copier le dossier sur un autre serveur sans rien modifier dedans.
Il suffit ensuite de changer l'adresse du `versions.json` dans les réglages du menu Versions de chaque site.

## Fonctionnement

1. Le site télécharge `versions.json` (mis en cache quelques heures, bouton « Actualiser »).
2. Pour chaque version, il construit l'adresse du zip à partir de celle du `versions.json` et du champ `file`.
3. Au clic sur « Installer », il télécharge le zip et calcule son empreinte SHA-256. Si elle ne correspond pas à
   `sha256` dans `versions.json`, l'installation s'arrête avant de toucher au thème.
4. Si tout correspond, le thème est remplacé par celui du zip (le zip doit contenir un dossier `corbuilder/`).

L'empreinte détecte un fichier corrompu ou remplacé. Elle ne protège pas contre quelqu'un qui contrôle aussi
`versions.json` : il peut changer le lien et l'empreinte en même temps. Il faut donc protéger l'endroit où
est hébergé le dossier (compte GitHub avec double authentification, accès SSH au serveur, etc.).

## Format de versions.json

```json
{
  "name": "Corbuilder",
  "versions": [
    {
      "version": "2.4.0",
      "file": "corbuilder-2.4.0.zip",
      "sha256": "…64 caractères…",
      "date": "2026-10-17",
      "notes": ["Première note", "Deuxième note"]
    }
  ]
}
```

Versions de la plus récente à la plus ancienne. `notes` peut être vide.

## Sortir une nouvelle version

1. **Préparer le thème** : passer le numéro à la nouvelle version dans `style.css` (`Version:`) et `functions.php`
   (`CORBUILDER_VERSION`), et ajouter l'entrée dans `inc/changelog.php`.
2. **Fabriquer le zip** : le zip doit contenir un seul dossier racine `corbuilder/`, nommé exactement ainsi :
   `zip -r corbuilder-2.5.0.zip corbuilder`
   Le nom du fichier suit toujours le format `corbuilder-x.y.z.zip` (points, pas de tirets bas).
3. **Copier le zip** dans ce dossier.
4. **Notes (facultatif)** : créer `notes/2.5.0.txt`, une note par ligne.
5. **Régénérer la liste** : `bash build-versions.sh`
   Le script lit tous les `corbuilder-x.y.z.zip`, recalcule les empreintes et réécrit `versions.json`.
6. **Publier** : envoyer `versions.json`, le nouveau zip et les notes sur l'hébergement (voir plus bas).
7. **Vérifier** : ouvrir l'adresse du `versions.json` dans un navigateur, puis cliquer sur « Actualiser »
   dans le menu Versions d'un site : la nouvelle version doit apparaître.

Ne jamais modifier un zip déjà publié : si une correction est nécessaire, sortir une nouvelle version
(2.5.1). Sinon l'empreinte ne correspond plus.

Retirer une version : supprimer son zip du dossier et relancer `bash build-versions.sh`.

## Publier sur GitHub Pages

Une fois :
1. Créer un dépôt public `Corbuilder` sur github.com.
2. Y envoyer tout le contenu du dossier (« Add file » → « Upload files », ou `git push`).
3. Dépôt → Settings → Pages → « Deploy from a branch », branche `main`, dossier `/ (root)` → Save.
4. Après une ou deux minutes, le dossier est servi à `https://TON-COMPTE.github.io/Corbuilder/`,
   donc la liste est à `https://TON-COMPTE.github.io/Corbuilder/versions.json`.

À chaque version : renvoyer le nouveau zip, `versions.json` et les notes dans le dépôt, puis attendre une à deux minutes.

Le dépôt étant public, les zips sont téléchargeables par tout le monde.

## Publier sur un serveur à soi (Caddy, nginx…)

Copier le dossier dans un répertoire servi en statique en HTTPS, par exemple avec Caddy :

```
versions.louiscorbet.fr {
    root * /srv/corbuilder-versions
    file_server
}
```

Le menu Versions n'y voit aucune différence : seule l'adresse du `versions.json` change.

## Dépannage

- **« Aucun fichier corbuilder-x.y.z.zip trouvé »** : le script se lance depuis ce dossier et ne reconnaît que
  les noms au format `corbuilder-2.5.0.zip`.
- **Empreinte refusée à l'installation** : le zip publié n'est pas celui dont `versions.json` a été calculé.
  Relancer le script après avoir mis le bon zip, et republier les deux.
- **La liste n'est pas à jour sur un site** : bouton « Actualiser » (la liste est gardée en cache).
- **Installation impossible** : WordPress doit pouvoir écrire dans le dossier des thèmes (droits du dossier
  `wp-content/themes`, constante `DISALLOW_FILE_MODS`, volume Docker en lecture seule).
- **Retour à une ancienne version** : le thème est remplacé, mais les réglages enregistrés ne reviennent pas en
  arrière (par exemple les couleurs converties vers la palette en 2.4.0). Exporter les réglages avant (Corbuilder
  → Exporter) pour pouvoir les réimporter.
