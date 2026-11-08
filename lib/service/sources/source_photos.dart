import 'package:spiphoto_app/service/image_wp_info.dart';
import 'package:spiphoto_app/service/sources/modeles.dart';

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
