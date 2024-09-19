import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class WallpaperScreen {
  static const platform = MethodChannel('fr.enkirche/wallpaper');

  // Méthode pour définir le fond d'écran via le MethodChannel
  Future<void> setWallpaper(String imageUrl, int wallpaperType) async {
    try {
      final result = await platform.invokeMethod('setWallpaper', {
        'imageUrl': imageUrl,
        'wallpaperType': wallpaperType,
      });
      print(result); // Affiche le message de succès ou autre action si besoin
    } on PlatformException catch (e) {
      print("Erreur lors de la définition du fond d'écran : '${e.message}'.");
    }
  }

  // Boîte de dialogue pour demander à l'utilisateur où appliquer le fond d'écran
  void showWallpaperDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choisir l\'écran'),
          content:
              Text('Où voulez-vous définir l\'image comme fond d\'écran ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setWallpaper(imageUrl, 1); // Écran d'accueil
              },
              child: Text('Écran d\'accueil'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setWallpaper(imageUrl, 2); // Écran de verrouillage
              },
              child: Text('Écran de verrouillage'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setWallpaper(imageUrl, 3); // Les deux
              },
              child: Text('Les deux'),
            ),
          ],
        );
      },
    );
  }
}
