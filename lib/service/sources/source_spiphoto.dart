import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';
import 'package:spiphoto_app/service/sources/modeles.dart';
import 'package:spiphoto_app/service/sources/source_photos.dart';

/// Albums du site du club (articles WordPress), seule source qui autorise
/// les favoris.
class SourceSpiphoto extends SourcePhotos {
  const SourceSpiphoto();

  static final SourceConfig configuration = SourceConfig(
    type: TypeSource.spiphoto,
    adresse: Uri.parse('https://www.spiphoto.fr/'),
    nom: 'spiphoto.fr',
  );

  static const String _api = 'https://www.spiphoto.fr/wp-json/wp/v2';

  @override
  SourceConfig get config => configuration;

  @override
  bool get favorisPossibles => true;

  // ───────────────────────────────────────────────────────────────────────
  // CATÉGORIES
  // ───────────────────────────────────────────────────────────────────────

  @override
  Future<List<Categorie>> categories() async {
    final response = await http.get(Uri.parse('$_api/categories'
        '?hide_empty=true&per_page=100&_fields=id,name,count'));
    if (response.statusCode != 200) {
      throw Exception(
          'Impossible de charger les catégories (${response.statusCode})');
    }
    return categoriesDepuisJson(jsonDecode(response.body));
  }

  static List<Categorie> categoriesDepuisJson(Object? json) => json is List
      ? json
          .whereType<Map<String, dynamic>>()
          .where((c) => c['id'] is int && c['name'] is String)
          .map((c) => Categorie(
                id: '${c['id']}',
                nom: (c['name'] as String).replaceAll('&amp;', '&'),
                nbAlbums: c['count'] is int ? c['count'] as int : null,
              ))
          .toList()
      : const [];

  // ───────────────────────────────────────────────────────────────────────
  // ALBUMS
  // ───────────────────────────────────────────────────────────────────────

  /// Charge une page de 10 albums (taille par défaut de l'API WordPress).
  /// `_fields` ne garde que les champs lus par [albumDepuisJson] : les
  /// photos arrivent par `spi_images` (extension « SPIPHOTO Site » du site,
  /// includes/app-api.php), sans le HTML de l'article. `_links.author` reste
  /// nécessaire, sans lui `_embed` ne renvoie plus l'auteur.
  /// Le serveur (o2switch) ne compresse pas application/json : `_spi_gz`
  /// demande à l'extension du site de servir la réponse sous un type que le
  /// serveur compresse en gzip (environ 95 % de moins). Le corps reste du
  /// JSON, décompressé automatiquement par le client HTTP.
  @override
  Future<PageAlbums> albums({int page = 1, String? categorieId}) async {
    final response = await http.get(
      Uri.parse('$_api/posts'
          '?_embed=author'
          '&_fields=id,link,title.rendered,spi_images,_links.author,_embedded'
          '&_spi_gz=1'
          '&page=$page'
          '${categorieId != null ? '&categories=$categorieId' : ''}'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      final int? total = int.tryParse(response.headers['x-wp-total'] ?? '');
      final int totalPages =
          int.tryParse(response.headers['x-wp-totalpages'] ?? '') ?? page;
      if (page == 1 && categorieId == null) {
        await _enregistrerPremierePage(jsonList, total, totalPages);
      }
      return _pageAlbums(jsonList, total, totalPages);
    } else {
      throw Exception(
          'Impossible de charger les albums (${response.statusCode})');
    }
  }

  /// Les photos arrivent avec la liste des albums (`spi_images`).
  @override
  Future<List<ImageWpInfo>> photos(Album album) async => album.images;

  /// Un article de `wp/v2/posts`.
  static Album albumDepuisJson(Map<String, dynamic> json) {
    final String title = (json['title']['rendered'] is String
            ? json['title']['rendered'] as String
            : '')
        .replaceAll('&rsquo;', '’');
    // Légende de partage : titre de l'album et lien vers l'article.
    final String description =
        [title, json['link']].whereType<String>().join('\n');
    final images = json['spi_images'];
    return Album(
      id: json['id'] is int ? '${json['id']}' : '0',
      title: title,
      authorName: _authorNameFrom(json),
      images: images is List
          ? images
              .whereType<Map<String, dynamic>>()
              .map((image) =>
                  ImageWpInfo.fromJson(image, description: description))
              .where((image) => image.landscapeUrl.isNotEmpty)
              .toList()
          : const [],
    );
  }

  static String? _authorNameFrom(Map<String, dynamic> json) {
    final authors = json['_embedded']?['author'];
    if (authors is List && authors.isNotEmpty && authors.first is Map) {
      final name = authors.first['name'];
      if (name is String && name.isNotEmpty) return name;
    }
    return null;
  }

  static PageAlbums _pageAlbums(
      List<dynamic> jsonList, int? total, int totalPages) {
    final List<Album> albums = jsonList
        .map((json) => albumDepuisJson(json as Map<String, dynamic>))
        .toList();
    return PageAlbums(
      albums: albums,
      total: total ?? albums.length,
      totalPages: totalPages,
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // COPIE LOCALE DE LA PREMIÈRE PAGE
  // ───────────────────────────────────────────────────────────────────────

  /// Dernière première page reçue, gardée sur l'appareil : l'accueil
  /// s'affiche aussitôt au lancement, même hors ligne, puis se met à jour
  /// depuis le réseau. Les vignettes, elles, sont dans le cache disque des
  /// images. Le fichier garde la réponse brute de WordPress.
  static Future<File> get _fichierPremierePage async => File(
      '${(await getApplicationSupportDirectory()).path}/albums_page1.json');

  static Future<void> _enregistrerPremierePage(
      List<dynamic> jsonList, int? total, int totalPages) async {
    try {
      await (await _fichierPremierePage).writeAsString(jsonEncode({
        'total': total,
        'totalPages': totalPages,
        'albums': jsonList,
      }));
    } catch (_) {
      // Copie facultative : un échec d'écriture ne doit pas bloquer l'accueil.
    }
  }

  /// La dernière première page enregistrée, ou null s'il n'y en a pas
  /// (premier lancement) ou si elle est illisible.
  @override
  Future<PageAlbums?> premierePageEnregistree() async {
    try {
      final File fichier = await _fichierPremierePage;
      if (!fichier.existsSync()) return null;
      return pageDepuisCache(jsonDecode(await fichier.readAsString()));
    } catch (_) {
      return null;
    }
  }

  /// Contenu du fichier de la 1re page (lève une exception s'il est
  /// illisible).
  static PageAlbums pageDepuisCache(Map<String, dynamic> json) => _pageAlbums(
      json['albums'] as List<dynamic>,
      json['total'] as int?,
      json['totalPages'] as int);
}
