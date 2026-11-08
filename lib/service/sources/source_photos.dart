import 'package:spiphoto_app/service/image_wp_info.dart';
import 'package:spiphoto_app/service/sources/modeles.dart';

/// User-agent des requêtes vers les galeries externes : l'hébergeur des
/// galeries des adhérents répond 429 au user-agent par défaut.
const String userAgentSources = 'SPIPHOTO/1.0 (+https://www.spiphoto.fr)';

/// Adresse d'une galerie ramenée à sa racine en https quand c'est un
/// sous-domaine de spiphoto.fr (les liens http répondent aussi en https),
/// sans requête ni fragment, terminée par « / ».
Uri racineSource(Uri adresse) {
  final bool clubSpiphoto =
      adresse.host == 'spiphoto.fr' || adresse.host.endsWith('.spiphoto.fr');
  String chemin = adresse.path;
  if (!chemin.endsWith('/')) chemin = '$chemin/';
  return Uri(
    scheme: clubSpiphoto ? 'https' : adresse.scheme,
    host: adresse.host,
    port: adresse.hasPort ? adresse.port : null,
    path: chemin,
  );
}

/// Albums par page pour les sources qui donnent tous leurs albums d'un coup
/// (pagination côté appli), comme l'API WordPress de spiphoto.fr.
const int albumsParPage = 10;

/// Page [page] (à partir de 1) d'une liste d'albums complète.
PageAlbums pageDepuisListe(List<Album> albums, int page) {
  final int debut = (page - 1) * albumsParPage;
  return PageAlbums(
    albums: debut >= albums.length || debut < 0
        ? const []
        : albums.sublist(
            debut, (debut + albumsParPage).clamp(0, albums.length)),
    total: albums.length,
    totalPages: (albums.length / albumsParPage).ceil(),
  );
}

/// Ce que toute source de photos (spiphoto.fr, Piwigo, Lychee, WordPress)
/// sait fournir à l'interface.
abstract class SourcePhotos {
  const SourcePhotos();

  SourceConfig get config;

  /// Vrai uniquement pour spiphoto.fr : les photos ont alors un `mediaId`.
  bool get favorisPossibles;

  /// Catégories proposées en filtre (liste vide si la source n'en a pas).
  Future<List<Categorie>> categories();

  /// Albums paginés (page à partir de 1), éventuellement filtrés.
  Future<PageAlbums> albums({int page = 1, String? categorieId});

  /// Photos d'un album (chargées à l'ouverture si `album.images` est vide).
  Future<List<ImageWpInfo>> photos(Album album);

  /// Dernière 1re page gardée sur l'appareil, ou null.
  Future<PageAlbums?> premierePageEnregistree() async => null;
}
