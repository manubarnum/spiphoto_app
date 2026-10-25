# 📸 SPIPHOTO App

Application mobile du club photo **SPIPHOTO**, développée avec Flutter. Elle permet aux membres du club de parcourir les albums publiés sur le site WordPress du club, de garder leurs photos préférées, de découvrir celles que le club préfère, et de poser une photo en fond d'écran.

---

## ✨ Fonctionnalités

- 🏠 **Accueil mosaïque** — l'album le plus récent en photo à la une, puis tous les albums par paires, chargés au fil du défilement
- 🖼️ **Albums** — grille de photos (2 colonnes en portrait, 4 en paysage), titre, auteur et nombre de photos
- 🔍 **Visionneuse plein écran** — swipe entre les photos, zoom (pinch-to-zoom), barre d'actions fond d'écran / favori / partage
- 🖥️ **Fond d'écran avec aperçu** — choix de l'écran (accueil, verrouillage ou les deux), recadrage (zoom et déplacement) dans une maquette aux proportions du téléphone, puis pose
- ❤️ **Mes favoris** — les photos mises en favori, de la plus récente à la plus ancienne, synchronisées en temps réel
- 👥 **Le Club** — les photos préférées des membres, triables par nombre de favoris ou par date, avec les membres qui les ont choisies
- 👤 **Compte** — connexion Google réservée aux comptes **@spiphoto.fr**, depuis l'icône en haut à droite
- 🌗 **Mode jour / nuit** — même palette et même comportement que le site : suit le réglage du téléphone, puis garde le choix de l'utilisateur
- 📤 **Partage** — partage d'une image avec légende via les apps installées

---

## 🛠️ Technologies utilisées

| Technologie | Usage |
|---|---|
| [Flutter](https://flutter.dev) / [Dart](https://dart.dev) | Framework et langage |
| WordPress REST API | Source des albums et des photos |
| Firebase Auth + `google_sign_in` | Connexion Google des membres (@spiphoto.fr) |
| Cloud Firestore | Favoris des membres et fil du Club |
| `http`, `html` | Appels à l'API WordPress, extraction des images des articles |
| `extended_image` | Visionneuse avec zoom et cache des images |
| `share_plus` | Partage natif d'images |
| `shared_preferences` | Mémorisation du mode jour / nuit |
| `url_launcher` | Ouverture du site du club |

---

## 📁 Structure du projet

Organisation de type MVC : les services (`service/`) ne contiennent aucun code d'interface, les écrans (`interface/`) affichent les données et les messages.

```
lib/
├── main.dart                          # Point d'entrée, thèmes jour / nuit, navigation à 3 onglets
├── spi_colors.dart                    # Couleurs de marque et palette par thème (context.spi)
├── interface/
│   ├── appbar_accueil.dart            # Barre d'app : logo (retour accueil), site, jour / nuit, compte
│   ├── bottom_nav.dart                # Nav basse : Albums · Mes favoris · Club
│   ├── album_list.dart                # Accueil mosaïque (photo à la une + albums)
│   ├── album_details_screen.dart      # Écran d'un album
│   ├── build_grid_view.dart           # Grille de photos
│   ├── build_page_view.dart           # Visionneuse plein écran
│   ├── wallpaper_preview_screen.dart  # Aperçu et pose du fond d'écran
│   ├── favoris_screen.dart            # Mes favoris
│   ├── club_screen.dart               # Le Club
│   ├── compte_sheet.dart              # Panneau « Mon compte »
│   └── connexion_requise.dart         # Invitation à se connecter
└── service/
    ├── acces_wordpress.dart           # API WordPress (pagination) + modèle Album
    ├── image_wp_info.dart             # Modèle ImageWpInfo
    ├── auth_service.dart              # Connexion Google / Firebase Auth
    ├── favorites_service.dart         # Favoris et fil du Club (Firestore)
    ├── firestore.rules                # Règles de sécurité Firestore (référence)
    ├── theme_service.dart             # Choix jour / nuit persistant
    ├── share_service.dart             # Partage d'images
    └── wallpaper_service.dart         # Fond d'écran (MethodChannel Android)

android/app/src/main/kotlin/.../MainActivity.kt   # Pose du fond d'écran (recadrage), moteur Flutter en cache
test/
└── theme_service_test.dart            # Tests du mode jour / nuit

assets/
└── icons/
    └── mon_logo1.png                  # Logo de l'application
```

---

## 📲 Téléchargement

| Public | Lien |
|---|---|
| 👥 **Membres SPIPHOTO** | Play Store du Workspace SPIPHOTO (accès réservé aux comptes @spiphoto.fr) |
| 🌍 **Visiteurs / Développeurs** | [⬇️ Télécharger l'APK](../../releases/latest) — voir les Releases GitHub |

> ⚠️ Pour installer l'APK sur Android, activez **"Sources inconnues"** dans les paramètres de sécurité de votre appareil. La connexion, les favoris et le Club restent réservés aux comptes @spiphoto.fr.

---

## 🚀 Installation & lancement (développement)

### Prérequis

- [Flutter SDK](https://flutter.dev/docs/get-started/install) récent (testé avec **Flutter 3.47.8**) — il impose Gradle ≥ 8.14 et Android Gradle Plugin ≥ 8.11.1, déjà configurés dans le projet (Gradle 8.14.3, AGP 8.11.1)
- Android Studio et un SDK Android
- Un appareil Android ou un émulateur

### Étapes

```bash
# Cloner le projet
git clone https://github.com/manubarnum/spiphoto_app.git
cd spiphoto_app

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run

# Lancer les tests
flutter test
```

---

## 🏗️ Générer l'application

```bash
# Bundle pour le Play Store (signé avec la clé de android/key.properties)
flutter build appbundle --release

# APK de release, optimisés par architecture
flutter build apk --split-per-abi

# ou APK universel (compatible tous appareils)
flutter build apk
```

Les fichiers générés se trouvent dans :
```
build/app/outputs/bundle/release/app-release.aab   # Bundle Play Store
build/app/outputs/flutter-apk/
├── app-arm64-v8a-release.apk   # Appareils récents (recommandé)
├── app-armeabi-v7a-release.apk # Appareils anciens
└── app-release.apk              # APK universel
```

> 🔑 `android/key.properties` (clé de signature) n'est pas versionné : il doit être présent sur la machine qui génère la version de release.
> Avant d'envoyer une nouvelle version sur le Play Store, augmentez le numéro après le `+` dans `pubspec.yaml` (`version: x.y.z+N`).

---

## 📱 Plateformes supportées

| Plateforme | Statut |
|---|---|
| Android | ✅ Supporté |
| iOS | ⚠️ Non configuré (pas de configuration Firebase iOS, pas de fond d'écran) |
| Web / macOS / Linux / Windows | ⚠️ Non maintenu |

> ⚠️ La fonctionnalité **fond d'écran** utilise un `MethodChannel` natif (`fr.enkirche/wallpaper`) disponible uniquement sur Android.

---

## ⚙️ Configuration

### WordPress

L'URL de l'API est définie dans `lib/service/acces_wordpress.dart`. Les albums sont chargés par pages de 10, avec le nom de l'auteur :

```dart
'https://www.spiphoto.fr/wp-json/wp/v2/posts?_embed=author&page=$page'
```

### Firebase

- `android/app/google-services.json` contient la configuration du projet Firebase.
- La connexion est limitée au domaine **@spiphoto.fr** (`lib/service/auth_service.dart`).
- Les règles de sécurité Firestore sont gardées pour référence dans `lib/service/firestore.rules` ; elles se déploient depuis la console Firebase.
- Collections utilisées :

| Collection | Contenu |
|---|---|
| `favoriteEvents/{uid}_{photo}` | Un favori : `userId`, `mediaId`, `photoUrl`, `createdAt`, et depuis la refonte `userName`, `userPhoto`, `albumTitle` (affichés dans le Club) |
| `photoStats/{photo}` | `favoriteCount` : nombre de favoris par photo |

> 🔐 Si l'app est signée par le Play Store (Play App Signing), déclarez l'empreinte **SHA-1** de la clé de signature Play dans la console Firebase, sans quoi la connexion Google échoue dans la version installée depuis le Store.

### Mode jour / nuit

Le choix est enregistré sous la clé `spiphoto-theme` (`light` / `dark`), comme sur le site. Sans choix enregistré, l'app suit le réglage du téléphone.

---

## 🤝 Contribution

Ce projet est développé pour le club **SPIPHOTO**. Les contributions sont les bienvenues — ouvrez une issue ou une pull request !

---

## 📄 Licence

Ce projet est sous licence **MIT** — voir le fichier [LICENSE](LICENSE) pour plus de détails.

© 2024 SPIPHOTO — Emmanuel ENKIRCHE
