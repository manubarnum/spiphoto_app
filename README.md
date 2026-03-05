# 📸 SPIPHOTO App

Application mobile du club photo **SPIPHOTO**, développée avec Flutter. Elle permet aux membres du club de consulter les albums photos publiés sur le site WordPress du club, de visualiser les images en plein écran, de les partager et de les définir comme fond d'écran.

---

## ✨ Fonctionnalités

- 📋 **Liste des albums** — affichage des articles WordPress sous forme de cartes avec aperçu de la première photo
- 🖼️ **Galerie de photos** — grille responsive (2 colonnes en portrait, 4 en paysage) pour chaque album
- 🔍 **Visionneuse plein écran** — navigation par swipe entre les photos avec zoom (pinch-to-zoom)
- 📤 **Partage** — partage d'une image avec légende via les apps installées (Instagram, WhatsApp, etc.)
- 🖥️ **Fond d'écran** — définir une photo comme fond d'écran (écran d'accueil, verrouillage ou les deux)

---

## 🛠️ Technologies utilisées

| Technologie | Usage |
|---|---|
| [Flutter](https://flutter.dev) | Framework mobile multiplateforme |
| [Dart](https://dart.dev) | Langage de programmation |
| WordPress REST API | Source des albums et photos |
| `http` | Requêtes HTTP vers l'API WordPress |
| `html` | Parsing HTML pour extraire les URLs d'images |
| `extended_image` | Affichage avancé avec zoom et gestes |
| `share_plus` | Partage natif d'images |
| `url_launcher` | Ouverture de liens externes |
| `easy_image_viewer` | Visionneuse d'images simplifiée |

---

## 📁 Structure du projet

```
lib/
├── main.dart                          # Point d'entrée, navigation principale
├── interface/
│   ├── appbar_accueil.dart            # Barre de navigation supérieure
│   ├── bottom_appli.dart              # Barre de navigation inférieure
│   ├── album_list.dart                # Écran liste des albums
│   ├── album_details_screen.dart      # Écran détail d'un album
│   ├── build_grid_view.dart           # Widget grille de photos
│   └── build_page_view.dart           # Visionneuse plein écran avec swipe
└── service/
    ├── acces_wordpress.dart           # Appels API WordPress + modèle Album
    ├── image_wp_info.dart             # Modèle ImageWpInfo
    ├── share_service.dart             # Service de partage d'images
    └── wallpaper_screen.dart          # Service fond d'écran (MethodChannel Android)

assets/
├── icons/
│   └── mon_logo1.png                  # Logo de l'application
└── ca/
    └── lets-encrypt-r3.pem            # Certificat SSL Let's Encrypt
```

---

## 📲 Téléchargement

| Public | Lien |
|---|---|
| 👥 **Membres SPIPHOTO** | Disponible sur le Play Store associatif (accès réservé) |
| 🌍 **Visiteurs / Développeurs** | [⬇️ Télécharger l'APK](../../releases/latest) — voir les Releases GitHub |

> ⚠️ Pour installer l'APK sur Android, activez **"Sources inconnues"** dans les paramètres de sécurité de votre appareil.

---

## 🏗️ Générer l'APK soi-même

```bash
# Cloner le projet
git clone https://github.com/manubarnum/spiphoto_app.git
cd spiphoto_app

# Installer les dépendances
flutter pub get

# Générer l'APK de release (optimisé par architecture)
flutter build apk --split-per-abi

# ou APK universel (compatible tous appareils)
flutter build apk
```

Les fichiers générés se trouvent dans :
```
build/app/outputs/flutter-apk/
├── app-arm64-v8a-release.apk   # Appareils récents (recommandé)
├── app-armeabi-v7a-release.apk # Appareils anciens
└── app-release.apk              # APK universel
```

---

## 🚀 Installation & lancement (développement)

### Prérequis

- [Flutter SDK](https://flutter.dev/docs/get-started/install) ≥ 3.3.3
- Android Studio ou Xcode (selon la cible)
- Un appareil Android/iOS ou émulateur

### Étapes

```bash
# Cloner le projet
git clone https://github.com/manubarnum/spiphoto_app.git
cd spiphoto_app

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run
```

---

## 📱 Plateformes supportées

| Plateforme | Statut |
|---|---|
| Android | ✅ Supporté |
| iOS | ✅ Supporté |
| Web | ⚠️ Partiel (pas de fond d'écran) |
| macOS / Linux / Windows | ⚠️ Partiel |

> ⚠️ La fonctionnalité **fond d'écran** utilise un `MethodChannel` natif (`fr.enkirche/wallpaper`) disponible uniquement sur Android.

---

## ⚙️ Configuration

L'URL de l'API WordPress est définie dans `lib/service/acces_wordpress.dart` :

```dart
Uri.parse('https://a6a1-408e804a28c4.wptiger.fr/wp-json/wp/v2/posts')
```

Pour pointer vers un autre site WordPress, modifiez cette URL.

---

## 🔒 Certificat SSL

Un certificat Let's Encrypt (`assets/ca/lets-encrypt-r3.pem`) est inclus pour assurer la connexion HTTPS avec le serveur WordPress.

---

## 🤝 Contribution

Ce projet est développé pour le club **SPIPHOTO**. Les contributions sont les bienvenues — ouvrez une issue ou une pull request !

---

## 📄 Licence

Ce projet est sous licence **MIT** — voir le fichier [LICENSE](LICENSE) pour plus de détails.

© 2024 SPIPHOTO — Emmanuel ENKIRCHE
