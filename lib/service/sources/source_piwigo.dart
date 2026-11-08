import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:spiphoto_app/service/image_wp_info.dart';
import 'package:spiphoto_app/service/sources/modeles.dart';
import 'package:spiphoto_app/service/sources/source_photos.dart';

/// Galerie Piwigo, lue en invité par son API `ws.php` : albums publics
/// seulement, sans favoris.
class SourcePiwigo extends SourcePhotos {
  @override
  final SourceConfig config;

  /// Photos demandées par appel à `pwg.categories.getImages`.
  static const int photosParAppel = 100;

  // Piwigo donne tous les albums d'un coup : la liste est gardée pour les
  // pages suivantes et rechargée à chaque demande de la page 1.
  List<Album>? _albums;

  SourcePiwigo(this.config);

  @override
  bool get favorisPossibles => false;

  /// La hiérarchie Piwigo est aplatie : pas de filtre par catégorie.
  @override
  Future<List<Categorie>> categories() async => const [];

  @override
  Future<PageAlbums> albums({int page = 1, String? categorieId}) async {
    if (page == 1 || _albums == null) {
      _albums = albumsDepuisJson(await _appel({
        'method': 'pwg.categories.getList',
        'recursive': 'true',
        'public': 'true',
      }));
    }
    return pageDepuisListe(_albums!, page);
  }

  @override
  Future<List<ImageWpInfo>> photos(Album album) async {
    final List<ImageWpInfo> photos = [];
    // Pages à partir de 0 ; plafond de sécurité à 20 appels (2 000 photos).
    for (int page = 0; page < 20; page++) {
      final Object? json = await _appel({
        'method': 'pwg.categories.getImages',
        'cat_id': album.id,
        'per_page': '$photosParAppel',
        'page': '$page',
      });
      final List<ImageWpInfo> lot = photosDepuisJson(json, album.title);
      photos.addAll(lot);
      if (lot.length < photosParAppel || photos.length >= _totalPhotos(json)) {
        break;
      }
    }
    return photos;
  }

  Future<Object?> _appel(Map<String, String> parametres) async {
    final Uri uri = apiDe(config.adresse)
        .replace(queryParameters: {'format': 'json', ...parametres});
    final response = await http.get(uri, headers: {
      'User-Agent': userAgentSources,
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Galerie Piwigo injoignable (${response.statusCode})');
    }
    final Object? json = jsonDecode(utf8.decode(response.bodyBytes));
    if (json is! Map || json['stat'] != 'ok') {
      throw Exception('Réponse Piwigo en erreur');
    }
    return json;
  }

  // ───────────────────────────────────────────────────────────────────────
  // LECTURE DES RÉPONSES (fonctions pures, testées)
  // ───────────────────────────────────────────────────────────────────────

  /// Adresse de l'API : racine de la galerie, sans `index.php…`, + ws.php.
  static Uri apiDe(Uri adresse) {
    final Uri racine = racineSource(adresse);
    final int index = racine.path.indexOf('/index.php');
    final String chemin =
        index == -1 ? racine.path : racine.path.substring(0, index + 1);
    return racine.replace(path: '${chemin}ws.php');
  }

  /// Albums de `pwg.categories.getList` : catégories ayant des photos en
  /// propre, les plus récemment alimentées d'abord.
  static List<Album> albumsDepuisJson(Object? json) {
    final Object? categories =
        json is Map ? (json['result']?['categories']) : null;
    if (categories is! List) return const [];
    final List<Map<String, dynamic>> retenues = categories
        .whereType<Map<String, dynamic>>()
        .where((c) => c['id'] != null && _entier(c['nb_images']) > 0)
        .toList()
      ..sort((a, b) =>
          '${b['date_last'] ?? ''}'.compareTo('${a['date_last'] ?? ''}'));
    return retenues.map((c) {
      final String titre = _texte(c['name_raw']) ?? _texte(c['name']) ?? '';
      final String? vignette = _texte(c['tn_url']);
      return Album(
        id: '${c['id']}',
        title: titre,
        images: const [],
        nbPhotosAnnonce: _entier(c['nb_images']),
        couverture: vignette == null
            ? null
            : ImageWpInfo(
                mediaId: null,
                thumbnailUrl: derivee(vignette, 'xs'),
                ecranUrl: derivee(vignette, 'xl'),
                landscapeUrl: derivee(vignette, 'xl'),
                description: titre,
              ),
      );
    }).toList();
  }

  /// Photos de `pwg.categories.getImages`.
  static List<ImageWpInfo> photosDepuisJson(Object? json, String titreAlbum) {
    final Object? images = json is Map ? (json['result']?['images']) : null;
    if (images is! List) return const [];
    return images
        .whereType<Map<String, dynamic>>()
        .map((image) {
          final Object? d = image['derivatives'];
          String? taille(String nom) =>
              d is Map ? _texte((d[nom]?['url'])) : null;
          // Original masqué aux visiteurs sur certaines galeries (pas
          // d'element_url) : la plus grande dérivée le remplace.
          final String? original = _texte(image['element_url']) ??
              _taillesDecroissantes.map(taille).whereType<String>().firstOrNull;
          if (original == null) return null;
          return ImageWpInfo(
            mediaId: null,
            thumbnailUrl: taille('xsmall') ??
                taille('small') ??
                taille('thumb') ??
                original,
            ecranUrl: taille('xxlarge') ??
                taille('xlarge') ??
                taille('large') ??
                original,
            landscapeUrl: original,
            description: [titreAlbum, _texte(image['page_url'])]
                .whereType<String>()
                .join('\n'),
          );
        })
        .whereType<ImageWpInfo>()
        .toList();
  }

  static const List<String> _taillesDecroissantes = [
    '4xlarge',
    '3xlarge',
    'xxlarge',
    'xlarge',
    'large',
    'medium',
    'small',
    'xsmall',
    '2small',
    'thumb',
    'square',
  ];

  /// Autre taille d'une image Piwigo à partir de sa vignette (`-th`) :
  /// `i.php` produit à la demande la dérivée voulue (`xs`, `xl`…). Une
  /// adresse d'une autre forme est rendue telle quelle.
  static String derivee(String vignette, String suffixe) {
    final RegExp th = RegExp(r'-th(\.[A-Za-z]+)$');
    if (!th.hasMatch(vignette)) return vignette;
    return vignette
        .replaceFirst('/_data/i/', '/i.php?/')
        .replaceFirstMapped(th, (m) => '-$suffixe${m[1]}');
  }

  static int _totalPhotos(Object? json) =>
      json is Map ? _entier((json['result']?['paging']?['total_count'])) : 0;

  static int _entier(Object? valeur) => valeur is int
      ? valeur
      : valeur is String
          ? int.tryParse(valeur) ?? 0
          : 0;

  static String? _texte(Object? valeur) =>
      valeur is String && valeur.isNotEmpty ? valeur : null;
}
