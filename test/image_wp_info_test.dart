import 'package:flutter_test/flutter_test.dart';
import 'package:spiphoto_app/service/acces_wordpress.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';

void main() {
  const String dossier =
      'https://www.spiphoto.fr/wordpress/wp-content/uploads/2026/05';

  group('cheminMedia', () {
    test('garde le chemin qui suit /wp-content/uploads/', () {
      expect(cheminMedia('$dossier/photo-scaled.jpg'),
          '2026/05/photo-scaled.jpg');
      // Même chemin depuis le site local.
      expect(
          cheminMedia(
              'http://192.168.1.5:8085/wp-content/uploads/2026/05/photo.jpg'),
          '2026/05/photo.jpg');
    });

    test('null hors du dossier des médias', () {
      expect(cheminMedia('https://www.spiphoto.fr/logo.png'), isNull);
    });

    test('urlMedia rajoute le préfixe de production', () {
      expect(urlMedia('2026/05/photo.jpg'), '$dossier/photo.jpg');
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
          'vignette': '$dossier/a-320x320.jpg',
          'ecran': '$dossier/a-1456x1920.jpg',
          'original': '$dossier/a-scaled.jpg',
        },
        {'original': '$dossier/b.jpg'},
      ],
    });
    expect(album.title, 'L’album');
    expect(album.images.map((i) => i.landscapeUrl),
        ['$dossier/a-scaled.jpg', '$dossier/b.jpg']);
    expect(album.images.first.mediaId, '60153');
    // Sans identifiant WordPress : pas de favori possible.
    expect(album.images.last.mediaId, isNull);
    expect(album.images.first.thumbnailUrl, '$dossier/a-320x320.jpg');
    expect(album.images.first.ecranUrl, '$dossier/a-1456x1920.jpg');
    // Taille absente : repli sur l'original.
    expect(album.images.last.thumbnailUrl, '$dossier/b.jpg');
    expect(album.images.first.description,
        'L’album\nhttps://www.spiphoto.fr/album/');
  });

  test('Album.fromJson sans spi_images : aucune photo', () {
    final Album album = Album.fromJson({
      'id': 2,
      'title': {'rendered': 'Vide'},
    });
    expect(album.images, isEmpty);
  });

  test('favori reconstruit les URL de production à partir des chemins', () {
    final ImageWpInfo info = ImageWpInfo.favori(
      mediaId: '60153',
      photoPath: '2026/05/a-scaled.jpg',
      vignettePath: '2026/05/a-320x320.jpg',
      ecranPath: '2026/05/a-1456x1920.jpg',
      album: 'Venise',
    );
    expect(info.mediaId, '60153');
    expect(info.landscapeUrl, '$dossier/a-scaled.jpg');
    expect(info.thumbnailUrl, '$dossier/a-320x320.jpg');
    expect(info.ecranUrl, '$dossier/a-1456x1920.jpg');
    expect(info.album, 'Venise');
  });

  test('favori sans vignette ni taille écran : repli sur l\'original', () {
    final ImageWpInfo info =
        ImageWpInfo.favori(mediaId: '1', photoPath: '2026/05/b.jpg');
    expect(info.thumbnailUrl, '$dossier/b.jpg');
    expect(info.ecranUrl, '$dossier/b.jpg');
  });
}
