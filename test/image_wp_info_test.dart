import 'package:flutter_test/flutter_test.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';

void main() {
  const String dossier =
      'https://www.spiphoto.fr/wordpress/wp-content/uploads/2026/05';

  group('stripWpImageSize', () {
    test('retire la taille avant une extension simple', () {
      expect(
          stripWpImageSize('$dossier/photo-300x300.jpg'), '$dossier/photo.jpg');
    });

    test('retire la taille avant une double extension WebP', () {
      expect(stripWpImageSize('$dossier/photo-150x150.jpeg.webp'),
          '$dossier/photo.jpeg.webp');
    });

    test('laisse intact un original', () {
      expect(stripWpImageSize('$dossier/photo-scaled.jpeg'),
          '$dossier/photo-scaled.jpeg');
      expect(stripWpImageSize('$dossier/photo.jpg.webp'),
          '$dossier/photo.jpg.webp');
    });
  });

  group('insertWpImageSize', () {
    test('insère avant une extension simple', () {
      expect(insertWpImageSize('$dossier/photo.jpg', '-320x320'),
          '$dossier/photo-320x320.jpg');
    });

    test('insère avant une double extension WebP', () {
      expect(insertWpImageSize('$dossier/photo.jpeg.webp', '-320x320'),
          '$dossier/photo-320x320.jpeg.webp');
    });
  });

  test('fromFavoriteUrl répare un favori enregistré en miniature WebP', () {
    final ImageWpInfo info =
        ImageWpInfo.fromFavoriteUrl('$dossier/photo-150x150.jpg.webp');
    expect(info.landscapeUrl, '$dossier/photo.jpg.webp');
    expect(info.thumbnailUrl, '$dossier/photo-320x320.jpg.webp');
  });
}
