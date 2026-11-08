import 'package:flutter_test/flutter_test.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';
import 'package:spiphoto_app/service/sources/modeles.dart';
import 'package:spiphoto_app/service/sources/source_spiphoto.dart';

void main() {
  group('SourceConfig', () {
    test('aller-retour JSON', () {
      final SourceConfig source = SourceConfig(
        type: TypeSource.piwigo,
        adresse: Uri.parse('https://galerie.exemple.fr/'),
        nom: 'Galerie de Jean',
        image: 'https://www.spiphoto.fr/vignette.webp',
        adherent: true,
      );
      final SourceConfig? relue = SourceConfig.depuisJson(source.toJson());
      expect(relue, source);
      expect(relue!.nom, 'Galerie de Jean');
      expect(relue.image, 'https://www.spiphoto.fr/vignette.webp');
      expect(relue.adherent, isTrue);
    });

    test('champs facultatifs absents', () {
      final SourceConfig? relue = SourceConfig.depuisJson({
        'type': 'wordpress',
        'adresse': 'https://blog.exemple.fr/',
        'nom': 'Blog',
      });
      expect(relue!.image, isNull);
      expect(relue.adherent, isFalse);
    });

    test('entrée incomplète ou de type inconnu : null', () {
      expect(SourceConfig.depuisJson(null), isNull);
      expect(
          SourceConfig.depuisJson(
              {'type': 'coppermine', 'adresse': 'https://a.fr/', 'nom': 'A'}),
          isNull);
      expect(SourceConfig.depuisJson({'type': 'piwigo', 'nom': 'A'}), isNull);
      expect(
          SourceConfig.depuisJson(
              {'type': 'piwigo', 'adresse': 'pas une adresse', 'nom': 'A'}),
          isNull);
    });
  });

  group('Album', () {
    ImageWpInfo photo(String nom) => ImageWpInfo(
          mediaId: null,
          thumbnailUrl: '$nom-vignette.jpg',
          ecranUrl: '$nom-ecran.jpg',
          landscapeUrl: '$nom.jpg',
          description: '',
        );

    test('couverture et nombre : 1re photo et photos chargées', () {
      final Album album =
          Album(id: 'a', title: 'A', images: [photo('p1'), photo('p2')]);
      expect(album.photoCouverture!.landscapeUrl, 'p1.jpg');
      expect(album.nbPhotos, 2);
    });

    test('album pas encore ouvert : couverture et nombre annoncés', () {
      final Album album = Album(
        id: 'ciDpHtGB_4ThiBytWId5HrI_',
        title: 'Lychee',
        images: const [],
        couverture: photo('c'),
        nbPhotosAnnonce: 9,
      );
      expect(album.photoCouverture!.landscapeUrl, 'c.jpg');
      expect(album.nbPhotos, 9);
    });

    test('sans photo ni couverture', () {
      final Album album = Album(id: 'v', title: 'Vide', images: const []);
      expect(album.photoCouverture, isNull);
      expect(album.nbPhotos, 0);
    });
  });

  group('SourceSpiphoto', () {
    test('seule source à autoriser les favoris', () {
      const SourceSpiphoto source = SourceSpiphoto();
      expect(source.favorisPossibles, isTrue);
      expect(source.config.type, TypeSource.spiphoto);
      expect(source.config.adresse.host, 'www.spiphoto.fr');
    });

    test('identifiant WordPress entier lu en texte', () {
      final Album album = SourceSpiphoto.albumDepuisJson({
        'id': 70412,
        'title': {'rendered': 'Gerberoy'},
      });
      expect(album.id, '70412');
    });

    test('relit la 1re page enregistrée par la version précédente', () {
      // Fichier albums_page1.json : réponse brute de WordPress.
      final PageAlbums page = SourceSpiphoto.pageDepuisCache({
        'total': 512,
        'totalPages': 52,
        'albums': [
          {
            'id': 70412,
            'link': 'https://www.spiphoto.fr/gerberoy/',
            'title': {'rendered': 'Gerberoy'},
            'spi_images': [
              {'id': 60153, 'original': 'https://www.spiphoto.fr/a.jpg'},
            ],
            '_embedded': {
              'author': [
                {'name': 'Alain'},
              ],
            },
          },
        ],
      });
      expect(page.total, 512);
      expect(page.totalPages, 52);
      expect(page.albums.single.id, '70412');
      expect(page.albums.single.authorName, 'Alain');
      expect(page.albums.single.images.single.mediaId, '60153');
    });

    test('cache illisible : exception (premierePageEnregistree rend null)', () {
      expect(() => SourceSpiphoto.pageDepuisCache({'albums': 'x'}),
          throwsA(anything));
    });

    test('catégories WordPress', () {
      final List<Categorie> categories = SourceSpiphoto.categoriesDepuisJson([
        {'id': 12, 'name': 'Ville et village', 'count': 40},
        {'id': 13, 'name': 'Fête &amp; spectacle', 'count': 3},
        {'id': 'x', 'name': 'invalide'},
      ]);
      expect(categories.map((c) => c.id), ['12', '13']);
      expect(categories.last.nom, 'Fête & spectacle');
      expect(categories.first.nbAlbums, 40);
      expect(SourceSpiphoto.categoriesDepuisJson(null), isEmpty);
    });
  });
}
