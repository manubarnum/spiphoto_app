import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class WallpaperScreen {
  static const platform = MethodChannel('fr.enkirche/wallpaper');

  // Méthode pour définir le fond d'écran via le MethodChannel
  Future<void> setWallpaper(
      BuildContext context, String imageUrl, int wallpaperType) async {
    try {
      await platform.invokeMethod('setWallpaper', {
        'imageUrl': imageUrl,
        'wallpaperType': wallpaperType,
      });

      // Confirmer le succès à l'utilisateur
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fond d\'écran défini avec succès !')),
      );
    } on PlatformException catch (e) {
      // Remonter l'erreur vers l'UI au lieu d'un print()
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Erreur lors de la définition du fond d\'écran : ${e.message}')),
      );
    }
  }

  // Boîte de dialogue pour demander à l'utilisateur où appliquer le fond d'écran
  void showWallpaperDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choisir l\'écran'),
          content: const Text(
              'Où voulez-vous définir l\'image comme fond d\'écran ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setWallpaper(context, imageUrl, 1); // Écran d'accueil
              },
              child: const Text('Écran d\'accueil'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setWallpaper(context, imageUrl, 2); // Écran de verrouillage
              },
              child: const Text('Écran de verrouillage'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setWallpaper(context, imageUrl, 3); // Les deux
              },
              child: const Text('Les deux'),
            ),
          ],
        );
      },
    );
  }
}
