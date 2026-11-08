import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';
import 'package:spiphoto_app/service/sources/modeles.dart';
import 'package:spiphoto_app/service/sources/source_lychee.dart';

/// Réponses réelles de deux galeries Lychee 7 (données publiques).
Object? fixture(String nom) =>
    jsonDecode(File('test/fixtures/$nom.json').readAsStringSync());

final Uri base = Uri.parse('https://lmphotos.spiphoto.fr/public/');

void main() {
  group('cookies de session', () {
    test('en-têtes multiples joints par des virgules, dates comprises', () {
      final Map<String, String> cookies = SourceLychee.cookiesDepuisEntete(
          'XSRF-TOKEN=eyJpdi%3D%3D; expires=Sun, 08 Nov 2026 18:00:00 GMT; '
          'Max-Age=7200; path=/; samesite=lax,'
          'lychee_session=eyJzZXNz; expires=Sun, 08 Nov 2026 18:00:00 GMT; '
          'path=/; httponly; samesite=lax');
      expect(cookies, {
        'XSRF-TOKEN': 'eyJpdi%3D%3D',
        'lychee_session': 'eyJzZXNz',
      });
    });

    test('en-tête absent ou vide', () {
      expect(SourceLychee.cookiesDepuisEntete(null), isEmpty);
      expect(SourceLychee.cookiesDepuisEntete(''), isEmpty);
    });
  });

  group('albums', () {
    final List<Map<String, dynamic>> racine =
        SourceLychee.albumsRacineDepuisJson(fixture('lychee_albums'));
    final List<Map<String, dynamic>> enfants =
        ((fixture('lychee_sous_albums') as Map)['data'] as List)
            .cast<Map<String, dynamic>>();

    test('albums de premier niveau', () {
      expect(racine, hasLength(17));
      expect(racine.first['title'], 'Abbaye de Saint Germer de Fly ');
    });

    test('albums partagés ajoutés, doublons et albums spéciaux ignorés', () {
      final List<Map<String, dynamic>> albums =
          SourceLychee.albumsRacineDepuisJson({
        'smart_albums': [
          {'id': 'recent', 'title': 'Récentes'},
        ],
        'albums': [
          {'id': 'a', 'title': 'A'},
        ],
        'shared_albums': [
          {'id': 'b', 'title': 'B'},
          {'id': 'a', 'title': 'A'},
        ],
      });
      expect(albums.map((a) => a['id']), ['a', 'b']);
      expect(SourceLychee.albumsRacineDepuisJson(null), isEmpty);
    });

    test('à plat : sous-albums « Parent › Enfant » à la place du parent',
        () async {
      final List<String> demandes = [];
      final List<Album> albums = await SourceLychee.albumsAplatis(
        racine.take(2).toList(),
        (id) async {
          demandes.add(id);
          return enfants;
        },
        base,
      );
      // Le parent (0 photo propre) est remplacé par ses deux enfants.
      expect(demandes, ['_vnDUBVvgdK7GXEJW7fr2ZYq']);
      expect(albums.map((a) => a.title), [
        'Abbaye de Saint Germer de Fly › Extérieur',
        'Abbaye de Saint Germer de Fly › Intérieur',
        'Animaux',
      ]);
      expect(albums.first.id, 'w6BwLCyCTcNIOoqpw4nSq-nt');
      expect(albums.first.nbPhotos, 15);
    });

    test('parent qui a aussi ses propres photos : gardé', () async {
      final List<Album> albums = await SourceLychee.albumsAplatis(
        [
          {'id': 'p', 'title': 'P', 'has_subalbum': true, 'num_photos': 4},
        ],
        (id) async => [
          {'id': 'e', 'title': 'E', 'has_subalbum': false, 'num_photos': 2},
        ],
        base,
      );
      expect(albums.map((a) => a.title), ['P', 'P › E']);
    });

    test('profondeur limitée', () async {
      int appels = 0;
      final List<Album> albums = await SourceLychee.albumsAplatis(
        [
          {'id': 'x', 'title': 'X', 'has_subalbum': true},
        ],
        (id) async {
          appels++;
          return [
            {'id': '$id+', 'title': 'X', 'has_subalbum': true},
          ];
        },
        base,
      );
      expect(appels, SourceLychee.profondeurMax);
      expect(albums, isEmpty);
    });

    test('nombre annoncé à 0 non fiable : inconnu, album gardé', () {
      final Album album = SourceLychee.albumDepuisJson(
          {'id': 'top', 'title': 'Top Picks', 'num_photos': 0, 'thumb': null},
          base);
      expect(album.nbPhotosAnnonce, isNull);
      expect(album.photoCouverture, isNull);
      expect(album.images, isEmpty);
    });

    test('couverture : vignette 2x, URL relative résolue, sans favori', () {
      final Album album = SourceLychee.albumDepuisJson({
        'id': 'a',
        'title': 'A',
        'num_photos': 3,
        'thumb': {
          'thumb': 'uploads/small/x.jpg',
          'thumb2x': 'uploads/small2x/x.jpg',
          'placeholder': 'data:image/webp;base64,xxx',
        },
      }, base);
      final ImageWpInfo couverture = album.photoCouverture!;
      expect(couverture.thumbnailUrl,
          'https://lmphotos.spiphoto.fr/public/uploads/small2x/x.jpg');
      expect(couverture.mediaId, isNull);
      expect(album.nbPhotos, 3);
    });
  });

  group('photos', () {
    test('les 9 photos, original masqué : medium2x à la place', () {
      final List<ImageWpInfo> photos = SourceLychee.photosDepuisJson(
          fixture('lychee_photos'), 'Flamme olympique', base);
      expect(photos, hasLength(9));
      final ImageWpInfo p = photos.first;
      expect(p.mediaId, isNull);
      expect(p.landscapeUrl, contains('/uploads/medium2x/'));
      expect(p.ecranUrl, contains('/uploads/medium/'));
      expect(p.thumbnailUrl, contains('/uploads/thumb2x/'));
      expect(p.description, 'Flamme olympique');
    });

    test('autre galerie (installée à la racine)', () {
      final List<ImageWpInfo> photos = SourceLychee.photosDepuisJson(
          fixture('lychee_photos_progpix'),
          'Top Picks',
          Uri.parse('https://progpix.spiphoto.fr/'));
      expect(photos, hasLength(14));
      expect(photos.first.ecranUrl,
          startsWith('https://progpix.spiphoto.fr/uploads/medium/'));
    });

    test('original accessible, vidéos ignorées, URL relatives', () {
      final List<ImageWpInfo> photos = SourceLychee.photosDepuisJson({
        'photos': [
          {
            'type': 'image/jpeg',
            'size_variants': {
              'original': {'url': 'uploads/original/o.jpg'},
              'medium': {'url': 'uploads/medium/o.jpg'},
              'thumb': {'url': 'uploads/thumb/o.jpg'},
              'placeholder': {'url': 'data:image/webp;base64,xxx'},
            },
          },
          {
            'type': 'video/mp4',
            'size_variants': {
              'original': {'url': 'uploads/original/v.mp4'},
            },
          },
          {'type': 'image/jpeg', 'size_variants': {}},
        ],
      }, 'A', base);
      expect(photos, hasLength(1));
      expect(photos.single.landscapeUrl,
          'https://lmphotos.spiphoto.fr/public/uploads/original/o.jpg');
      expect(photos.single.thumbnailUrl,
          'https://lmphotos.spiphoto.fr/public/uploads/thumb/o.jpg');
      expect(SourceLychee.photosDepuisJson(null, 'A', base), isEmpty);
    });
  });

  test('pas de favoris ni de catégories', () async {
    final SourceLychee source = SourceLychee(SourceConfig(
      type: TypeSource.lychee,
      adresse: Uri.parse('https://progpix.spiphoto.fr/'),
      nom: 'Colin',
    ));
    expect(source.favorisPossibles, isFalse);
    expect(await source.categories(), isEmpty);
  });
}
