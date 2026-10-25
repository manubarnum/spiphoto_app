import 'package:flutter/services.dart';

class WallpaperService {
  static const platform = MethodChannel('fr.enkirche/wallpaper');

  /// Pose le fond d'écran via le MethodChannel natif.
  /// [crop] : zone à conserver, en fractions de l'image (0..1) ; l'image
  /// entière si null. Lève une [PlatformException] en cas d'échec.
  Future<void> setWallpaper(String imageUrl, int wallpaperType,
      {Rect? crop}) async {
    await platform.invokeMethod('setWallpaper', {
      'imageUrl': imageUrl,
      'wallpaperType': wallpaperType,
      if (crop != null) 'crop': [crop.left, crop.top, crop.right, crop.bottom],
    });
  }
}
