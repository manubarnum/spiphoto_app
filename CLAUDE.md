# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projet

Application Flutter (Android uniquement en pratique) du club photo SPIPHOTO : albums du site WordPress du club, favoris et fil « Club » partagés via Firebase, agenda du club (flux iCal Google), pose de fond d'écran. Le code, les identifiants, les commentaires et les messages de commit sont en **français** (commits au format Conventional Commits : `feat(club): …`, `fix(visionneuse): …`, `perf(…)`, `chore(release): …`).

## Commandes

```bash
flutter pub get
flutter run                                   # appareil USB ou émulateur
flutter analyze                               # lints (flutter_lints, voir analysis_options.yaml)
flutter test                                  # tous les tests
flutter test test/agenda_service_test.dart    # un fichier
flutter test --plain-name 'favoriClubDepuisFiche sans membres'   # un test précis
cd firestore_test && npm install && npm test  # règles Firestore dans l'émulateur (Node + Java)
flutter build appbundle --release             # AAB Play Store (exige android/key.properties, non versionné)
flutter build apk --split-per-abi
```

Avant un envoi Play Store : incrémenter le numéro après `+` dans `pubspec.yaml`, puis poser une étiquette `vX.Y.Z+N` sur le commit construit.

## Architecture

Séparation stricte : `lib/service/` ne contient aucun code d'interface (pas de `BuildContext`, pas de messages utilisateur) ; `lib/interface/` affiche les données et les messages.

**Navigation** (`lib/main.dart`) : un `IndexedStack` de 3 onglets (Albums · Mes favoris · Club), chacun avec son propre `Navigator` (clé globale) pour garder la nav basse quand un album s'ouvre. Un onglet n'est construit qu'à sa première visite (`_ongletsVisites`) pour ne pas lancer les écoutes Firestore au démarrage. La barre d'accueil (`MyAppBarAccueil`) est portée par la page racine de chaque onglet, pas par le `Scaffold` global. Le retour Android est intercepté (`PopScope`, `_surRetour`) : dépile l'onglet actif, sinon revient à l'onglet Albums, sinon quitte (`SystemNavigator.pop`). Les écrans plein écran (visionneuse, aperçu du fond d'écran, agenda) sont poussés sur le Navigator racine (`rootNavigator: true`) pour masquer la nav basse ; l'album, lui, s'ouvre dans le Navigator de l'onglet (`pushNamed('/album_details_screen')`).

**Services** : singletons `X.instance` pour ceux qui ont un état (`AuthService`, `FavoritesService`, `ThemeService`), classes à méthodes statiques sinon (`AgendaService`, `WallpaperService`, `ShareService`). L'état réactif passe par `ValueNotifier`/`ValueListenable` (pas de package de gestion d'état).

**Thème** (`lib/spi_colors.dart`) : `SpiColors` = couleurs fixes de marque ; `SpiPalette` = `ThemeExtension` jour/nuit lue via `context.spi`. Toute couleur qui dépend du thème doit passer par `context.spi`, pas par `SpiColors`. Choix persisté sous la clé `spiphoto-theme` (même clé que le site) ; `null` = suivre l'appareil. La visionneuse (`build_page_view.dart`) et l'aperçu du fond d'écran (`wallpaper_preview_screen.dart`) utilisent encore des couleurs fixes sombres (point « À faire » du README).

**Photos WordPress** (`service/image_wp_info.dart`, `service/sources/source_spiphoto.dart`) : l'API REST `wp/v2/posts?_embed=author` (pages de 10) expose un champ `spi_images` ajouté par l'extension WordPress « SPIPHOTO Site » (`~/Projects/spiphoto-site`, `includes/app-api.php`, qui gère aussi `_spi_gz` ; elle remplace depuis le 07/11/2026 les mu-plugins `spi-images-rest.php` et `spi-gzip-rest.php`) avec, par photo, `id`, `vignette`, `ecran`, `original`. `ImageWpInfo.mediaId` = identifiant du média WordPress ; une photo sans `mediaId` ne peut pas être mise en favori.

**Sources de photos** (`service/sources/`) : l'onglet Albums lit ses albums par l'interface `SourcePhotos` (`source_photos.dart`, modèles `Album`, `PageAlbums`, `SourceConfig`, `Categorie` dans `modeles.dart`). Implémentations : `SourceSpiphoto` (seule où `favorisPossibles` est vrai) et `SourcePiwigo` (`ws.php` en invité, albums = catégories ayant des photos, pagination de 10 côté appli, original remplacé par la plus grande dérivée s'il est masqué)) et `SourceLychee` (`api/v2` de Lychee 6+ : session visiteur obligatoire, cookies `lychee_session` + `XSRF-TOKEN` relevés sur la page d'accueil en suivant les redirections, jeton renvoyé dans `X-XSRF-TOKEN`, nouvelle session sur 419 ; sous-albums mis à plat « Parent › Enfant » ; `num_photos` non fiable ; vidéos ignorées) ; les requêtes vers les galeries envoient `userAgentSources` (sinon 429 chez l'hébergeur des galeries du club). La lecture JSON est dans des méthodes statiques testées sur des réponses réelles (`test/fixtures/`) ; `SourcesService.instance` (`sources_service.dart`) gère les sources de l'utilisateur : spiphoto.fr toujours en tête et non supprimable, puis les galeries d'adhérents activées, puis les autres sites ; liste des galeries lue sur `https://www.spiphoto.fr/wp-json/sps/v1/galeries` (route de l'extension « SPIPHOTO Site », types `piwigo`/`lychee`, `autre` masqué), copie gardée pour le hors-ligne ; une galerie sortie de la liste quitte les sources ; préférences `spiphoto-sources`, `spiphoto-source-active`, `spiphoto-galeries-adherents` ; `sourcePour()` garde une instance par source ; interface : `interface/onglet_albums.dart` (bandeau « source ▾ » → panneau de choix, puces de catégories, `MyList` recréée par clé à chaque source/catégorie ; la copie locale de la 1re page ne sert que sans catégorie), `interface/sources_screen.dart` (interrupteurs des galeries, liste actualisée à l'ouverture et au tirer-pour-rafraîchir), l'album s'ouvre avec `(Album, SourcePhotos)` en argument de route et charge ses photos si `images` est vide ; `Album.nbPhotos` est null quand le nombre est inconnu (rien d'affiché) ; couvertures Piwigo en dérivées `me`/`la` (les tailles `xs`/`xl` peuvent être désactivées : réponse 400) ; toute photo d'une autre source doit avoir `mediaId = null`. `Album.id` est une chaîne ; un album peut avoir `images` vide tant qu'il n'est pas ouvert (`photoCouverture`, `nbPhotos`).

**Favoris et Club** (`service/favorites_service.dart`, règles dans `service/firestore.rules`, déployées à la main depuis la console Firebase) :
- `favoriteEvents/{uid}_{mediaId}` : un document par favori.
- `photoStats/{mediaId}` : fiche partagée (compteur `favoriteCount`, `lastAddedAt`, `membres.{uid}` avec nom/photo/date) qui alimente le fil du Club sans relire les événements.
- Les URL sont stockées en **chemins relatifs** à `/wp-content/uploads/` (`photoPath`, `vignettePath`, `ecranPath`, via `cheminMedia`/`urlMedia`) pour fonctionner avec le site local comme en production.
- Ajout/retrait = un seul `WriteBatch` sans lecture préalable ; l'idempotence repose sur les règles Firestore (recréer ou supprimer un événement inexistant fait rejeter tout le lot). Toute modification du modèle doit rester cohérente avec `firestore.rules` : le compteur de `photoStats` n'accepte +1/-1 que si l'événement du membre est créé/supprimé dans le même lot. Toute modification des règles se vérifie avec `firestore_test/` (scénarios à compléter) avant publication dans la console ; le site (`assets/favoris.js` de l'extension) écrit les mêmes lots que l'appli.
- Un seul abonnement Firestore aux favoris, partagé par tous les écrans, fermé au changement de compte.
- En cas d'écart, le code et `firestore.rules` font foi sur le README.

**Connexion** (`service/auth_service.dart`) : Google Sign-In + Firebase Auth, limitée au domaine `spiphoto.fr`. La version signée par Play App Signing exige son SHA-1 dans la console Firebase.

**Agenda** (`service/agenda_service.dart`) : parseur iCal maison (pas de dépendance), gère `RRULE`, `EXDATE`, événements sur plusieurs jours et conversion heure de Paris → UTC calculée à la main. Les dates en français sont formatées dans `interface/dates_agenda.dart` (pas de dépendance `intl`). Les fonctions pures (`parseIcs`, `upcoming`, `nextEvent`) sont celles testées.

**Fond d'écran** : `MethodChannel('fr.enkirche/wallpaper')` implémenté dans `android/app/src/main/kotlin/fr/enkirche/spiphoto_app/MainActivity.kt` (téléchargement, recadrage, pose ; moteur Flutter en cache). Android uniquement.

**Tests** : tests unitaires des fonctions pures et des modèles (pas de widget tests, pas de Firebase simulé) ; extraire la logique en méthodes statiques testables (ex. `FavoritesService.favoriClubDepuisFiche`) plutôt que de tester à travers Firestore.

## Divers

- `design_handoff/` (ignoré par git) contient la maquette de la refonte ; s'en écarter est permis si la cohérence d'usage l'exige, en le signalant.
- Test sur appareil : privilégier le téléphone Android branché en USB, l'émulateur API 37 étant instable.
