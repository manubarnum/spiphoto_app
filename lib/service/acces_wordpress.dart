import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:spiphoto_app/service/image_wp_info.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODÈLE ALBUM
// ─────────────────────────────────────────────────────────────────────────────
class Album {
  final int id;
  String title;

  /// Nom affiché de l'auteur, embarqué par WordPress via `_embed=author`.
  /// Null si l'auteur n'est pas fourni (compte supprimé, endpoint bloqué…).
  final String? authorName;

  /// Photos de l'album, dans l'ordre de la page (champ `spi_images`).
  final List<ImageWpInfo> images;

  Album({
    required this.id,
    required this.title,
    required this.images,
    this.authorName,
  }) {
    title = title.replaceAll('&rsquo;', '’');
  }

  factory Album.fromJson(Map<String, dynamic> json) {
    final String title = (json['title']['rendered'] is String
            ? json['title']['rendered'] as String
            : '')
        .replaceAll('&rsquo;', '\u2019');
    // Légende de partage : titre de l'album et lien vers l'article.
    final String description =
        [title, json['link']].whereType<String>().join('\n');
    final images = json['spi_images'];
    return Album(
      id: json['id'] is int ? json['id'] : 0,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// FETCH ALBUMS
// ─────────────────────────────────────────────────────────────────────────────

/// Une page d'albums, avec les totaux renvoyés par WordPress dans les
/// en-têtes X-WP-Total et X-WP-TotalPages.
class PageAlbums {
  final List<Album> albums;
  final int total;
  final int totalPages;

  const PageAlbums({
    required this.albums,
    required this.total,
    required this.totalPages,
  });
}

/// Charge une page de 10 albums (taille par défaut de l'API WordPress).
/// `_fields` ne garde que les champs lus par [Album.fromJson] : les photos
/// arrivent par `spi_images` (mu-plugin spi-images-rest.php du site), sans
/// le HTML de l'article. `_links.author` reste nécessaire, sans lui `_embed`
/// ne renvoie plus l'auteur.
/// Le serveur (o2switch) ne compresse pas application/json : `_spi_gz`
/// demande au mu-plugin du site de servir la réponse sous un type que le
/// serveur compresse en gzip (environ 95 % de moins). Le corps reste du
/// JSON, décompressé automatiquement par le client HTTP.
Future<PageAlbums> fetchAlbums({int page = 1}) async {
  final response = await http.get(
    Uri.parse('https://www.spiphoto.fr/wp-json/wp/v2/posts'
        '?_embed=author'
        '&_fields=id,link,title.rendered,spi_images,_links.author,_embedded'
        '&_spi_gz=1'
        '&page=$page'),
  );

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    final List<Album> albums =
        jsonList.map((json) => Album.fromJson(json)).toList();
    return PageAlbums(
      albums: albums,
      total:
          int.tryParse(response.headers['x-wp-total'] ?? '') ?? albums.length,
      totalPages:
          int.tryParse(response.headers['x-wp-totalpages'] ?? '') ?? page,
    );
  } else {
    throw Exception(
        'Impossible de charger les albums (${response.statusCode})');
  }
}
