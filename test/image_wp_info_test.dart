import 'package:flutter_test/flutter_test.dart';
import 'package:spiphoto_app/service/acces_wordpress.dart';
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

  test('Album.fromJson lit les photos de spi_images, dans l\'ordre', () {
    final Album album = Album.fromJson({
      'id': 1,
      'link': 'https://www.spiphoto.fr/album/',
      'title': {'rendered': 'L&rsquo;album'},
      'spi_images': [
        {
          'id': 60153,
          'vignette': '$dossier/a-320x320.jpg.webp',
          'ecran': '$dossier/a-1456x1920.jpg.webp',
          'original': '$dossier/a-scaled.jpg.webp',
        },
        {'original': '$dossier/b.jpg'},
      ],
    });
    expect(album.title, 'L\u2019album');
    expect(album.images.map((i) => i.landscapeUrl),
        ['$dossier/a-scaled.jpg.webp', '$dossier/b.jpg']);
    expect(album.images.first.mediaId, '60153');
    // Sans identifiant WordPress : URL d'original encodée.
    expect(album.images.last.mediaId, Uri.encodeComponent('$dossier/b.jpg'));
    expect(album.images.first.thumbnailUrl, '$dossier/a-320x320.jpg.webp');
    expect(album.images.first.ecranUrl, '$dossier/a-1456x1920.jpg.webp');
    // Taille absente : repli sur l'original.
    expect(album.images.last.thumbnailUrl, '$dossier/b.jpg');
    expect(album.images.first.description,
        'L\u2019album\nhttps://www.spiphoto.fr/album/');
  });

  test('Album.fromJson sans spi_images : aucune photo', () {
    final Album album = Album.fromJson({
      'id': 2,
      'title': {'rendered': 'Vide'},
    });
    expect(album.images, isEmpty);
  });

  test('fromFavoriteUrl reprend les URL enregistrées', () {
    final ImageWpInfo info = ImageWpInfo.fromFavoriteUrl(
      '$dossier/a-scaled.jpg.webp',
      mediaId: '60153',
      thumbnailUrl: '$dossier/a-320x320.jpg.webp',
      ecranUrl: '$dossier/a-1456x1920.jpg.webp',
    );
    expect(info.landscapeUrl, '$dossier/a-scaled.jpg.webp');
    expect(info.thumbnailUrl, '$dossier/a-320x320.jpg.webp');
    expect(info.ecranUrl, '$dossier/a-1456x1920.jpg.webp');
    expect(info.mediaId, '60153');
  });

  test('fromFavoriteUrl répare un favori enregistré en miniature WebP', () {
    final ImageWpInfo info =
        ImageWpInfo.fromFavoriteUrl('$dossier/photo-150x150.jpg.webp');
    expect(info.landscapeUrl, '$dossier/photo.jpg.webp');
    expect(info.thumbnailUrl, '$dossier/photo-320x320.jpg.webp');
  });
}
