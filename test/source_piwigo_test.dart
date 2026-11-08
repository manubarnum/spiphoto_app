import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';
import 'package:spiphoto_app/service/sources/modeles.dart';
import 'package:spiphoto_app/service/sources/source_photos.dart';
import 'package:spiphoto_app/service/sources/source_piwigo.dart';

/// Réponses réelles d'une galerie Piwigo 16.4 (données publiques).
Object? fixture(String nom) =>
    jsonDecode(File('test/fixtures/$nom.json').readAsStringSync());

void main() {
  group('adresse', () {
    test('ws.php à la racine, https pour les sous-domaines du club', () {
      expect(SourcePiwigo.apiDe(Uri.parse('http://thaldeso.spiphoto.fr')),
          Uri.parse('https://thaldeso.spiphoto.fr/ws.php'));
      expect(
          SourcePiwigo.apiDe(
              Uri.parse('https://alain.spiphoto.fr/index.php?/category/1')),
          Uri.parse('https://alain.spiphoto.fr/ws.php'));
    });

    test('galerie dans un sous-dossier, hors du club : schéma gardé', () {
      expect(SourcePiwigo.apiDe(Uri.parse('http://exemple.fr/galerie/')),
          Uri.parse('http://exemple.fr/galerie/ws.php'));
    });

    test('racineSource retire requête et fragment', () {
      expect(racineSource(Uri.parse('http://fred.declic.spiphoto.fr/?a=1#b')),
          Uri.parse('https://fred.declic.spiphoto.fr/'));
    });
  });

  group('albums', () {
    final List<Album> albums =
        SourcePiwigo.albumsDepuisJson(fixture('piwigo_categories'));

    test('les 6 catégories, les plus récemment alimentées d\'abord', () {
      expect(albums.map((a) => a.id), ['5', '6', '4', '3', '2', '1']);
      expect(albums.first.title, 'Flore jardin Cuy st Fiacre');
    });

    test('photos chargées à l\'ouverture, nombre annoncé', () {
      final Album automne = albums.last;
      expect(automne.images, isEmpty);
      expect(automne.nbPhotos, 35);
    });

    test('couverture : tailles dérivées de la vignette, sans favori', () {
      final ImageWpInfo couverture = albums.last.photoCouverture!;
      expect(couverture.mediaId, isNull);
      expect(couverture.thumbnailUrl,
          'https://alain.spiphoto.fr/i.php?/upload/2025/12/01/20251201120040-6fddf10f-me.jpg');
      expect(couverture.ecranUrl,
          'https://alain.spiphoto.fr/i.php?/upload/2025/12/01/20251201120040-6fddf10f-la.jpg');
      // Vignette déjà en cache (_data/i) : repassée par i.php.
      expect(albums.first.photoCouverture!.thumbnailUrl,
          'https://alain.spiphoto.fr/i.php?/upload/2025/12/29/20251229150916-3d11c6e7-me.jpg');
    });

    test('catégorie sans photo propre ou réponse invalide', () {
      expect(
          SourcePiwigo.albumsDepuisJson({
            'stat': 'ok',
            'result': {
              'categories': [
                {'id': 1, 'name': 'Parent', 'nb_images': 0},
                {'id': 2, 'name': 'Enfant', 'nb_images': '3'},
              ],
            },
          }).map((a) => a.id),
          ['2']);
      expect(SourcePiwigo.albumsDepuisJson(null), isEmpty);
      expect(SourcePiwigo.albumsDepuisJson({'stat': 'fail'}), isEmpty);
    });

    test('dérivée : adresse sans « -th » rendue telle quelle', () {
      expect(SourcePiwigo.derivee('https://g.fr/photo.jpg', 'xl'),
          'https://g.fr/photo.jpg');
    });
  });

  group('pagination côté appli', () {
    final List<Album> albums = List.generate(
        23, (i) => Album(id: '$i', title: 'A$i', images: const []));

    test('pages de 10, dernière page partielle', () {
      final PageAlbums p1 = pageDepuisListe(albums, 1);
      final PageAlbums p3 = pageDepuisListe(albums, 3);
      expect(p1.albums.map((a) => a.id).first, '0');
      expect(p1.albums, hasLength(10));
      expect(p3.albums.map((a) => a.id), ['20', '21', '22']);
      expect(p1.total, 23);
      expect(p1.totalPages, 3);
    });

    test('au-delà de la fin : page vide', () {
      expect(pageDepuisListe(albums, 4).albums, isEmpty);
      expect(pageDepuisListe(const [], 1).totalPages, 0);
    });
  });

  group('photos', () {
    final List<ImageWpInfo> photos =
        SourcePiwigo.photosDepuisJson(fixture('piwigo_images'), 'Automne');

    test('les 35 photos, sans favori possible', () {
      expect(photos, hasLength(35));
      expect(photos.every((p) => p.mediaId == null), isTrue);
    });

    test('tailles : xsmall en grille, xxlarge à l\'écran, original', () {
      final ImageWpInfo p = photos.first;
      expect(p.thumbnailUrl, endsWith('-xs.jpg'));
      expect(p.ecranUrl, endsWith('-xx.jpg'));
      expect(p.landscapeUrl,
          'https://alain.spiphoto.fr/upload/2025/12/01/20251201223512-95874d8a.jpg');
      expect(
          p.description, 'Automne\nhttps://alain.spiphoto.fr/picture.php?/40');
    });

    test('tailles absentes : repli sur l\'original', () {
      final List<ImageWpInfo> sans = SourcePiwigo.photosDepuisJson({
        'result': {
          'images': [
            {'element_url': 'https://g.fr/o.jpg'},
            {'derivatives': {}},
          ],
        },
      }, 'A');
      expect(sans, hasLength(1));
      expect(sans.single.thumbnailUrl, 'https://g.fr/o.jpg');
      expect(sans.single.ecranUrl, 'https://g.fr/o.jpg');
    });

    test('original masqué aux visiteurs : plus grande dérivée', () {
      final List<ImageWpInfo> masque = SourcePiwigo.photosDepuisJson({
        'result': {
          'images': [
            {
              'download_url': null,
              'derivatives': {
                'xsmall': {'url': 'https://g.fr/p-xs.jpg'},
                'xxlarge': {'url': 'https://g.fr/p-xx.jpg'},
                '4xlarge': {'url': 'https://g.fr/p-xx.jpg'},
              },
            },
          ],
        },
      }, 'A');
      expect(masque.single.landscapeUrl, 'https://g.fr/p-xx.jpg');
      expect(masque.single.thumbnailUrl, 'https://g.fr/p-xs.jpg');
    });
  });

  test('pas de favoris ni de catégories', () async {
    final SourcePiwigo source = SourcePiwigo(SourceConfig(
      type: TypeSource.piwigo,
      adresse: Uri.parse('https://alain.spiphoto.fr/'),
      nom: 'Alain',
    ));
    expect(source.favorisPossibles, isFalse);
    expect(await source.categories(), isEmpty);
    expect(await source.premierePageEnregistree(), isNull);
  });
}
