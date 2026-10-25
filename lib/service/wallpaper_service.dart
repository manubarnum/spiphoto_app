import 'dart:io';

import 'package:extended_image/extended_image.dart' show getCachedImageFile;
import 'package:flutter/services.dart';

class WallpaperService {
  static const platform = MethodChannel('fr.enkirche/wallpaper');

  /// Pose le fond d'écran via le MethodChannel natif.
  /// [crop] : zone à conserver, en fractions de l'image (0..1) ; l'image
  /// entière si null. Lève une [PlatformException] en cas d'échec.
  /// L'aperçu vient d'afficher l'image : le code natif la lit dans le cache
  /// disque d'ExtendedImage plutôt que de la retélécharger, et ne passe par
  /// l'URL qu'à défaut.
  Future<void> setWallpaper(String imageUrl, int wallpaperType,
      {Rect? crop}) async {
    final File? enCache = await getCachedImageFile(imageUrl);
    await platform.invokeMethod('setWallpaper', {
      'imageUrl': imageUrl,
      if (enCache != null) 'imagePath': enCache.path,
      'wallpaperType': wallpaperType,
      if (crop != null) 'crop': [crop.left, crop.top, crop.right, crop.bottom],
    });
  }
}
