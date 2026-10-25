import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:spiphoto_app/service/image_wp_info.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODÈLE ALBUM
// ─────────────────────────────────────────────────────────────────────────────
class Album {
  final Map<String, dynamic> content;
  final int id;
  String title;

  /// Nom affiché de l'auteur, embarqué par WordPress via `_embed=author`.
  /// Null si l'auteur n'est pas fourni (compte supprimé, endpoint bloqué…).
  final String? authorName;

  Album({
    required this.content,
    required this.id,
    required this.title,
    this.authorName,
  }) {
    title = title.replaceAll('&rsquo;', '\u2019');
  }

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      content: json['content'] ?? {},
      id: json['id'] is int ? json['id'] : 0,
      title:
          json['title']['rendered'] is String ? json['title']['rendered'] : '',
      authorName: _authorNameFrom(json),
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
/// Chaque album embarque le HTML complet de son article (~45 Ko) : on
/// pagine plutôt que de tout charger d'un coup.
/// `_fields` ne garde que les champs lus par [Album.fromJson] (environ 20 %
/// de moins) ; `_links.author` reste nécessaire, sans lui `_embed` ne
/// renvoie plus l'auteur.
Future<PageAlbums> fetchAlbums({int page = 1}) async {
  final response = await http.get(
    Uri.parse('https://www.spiphoto.fr/wp-json/wp/v2/posts'
        '?_embed=author'
        '&_fields=id,title.rendered,content.rendered,_links.author,_embedded'
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

// ─────────────────────────────────────────────────────────────────────────────
// EXTRACTION DES IMAGES DEPUIS LE HTML WORDPRESS
// ─────────────────────────────────────────────────────────────────────────────
Future<List<ImageWpInfo>> extractImagesFromHtml(String htmlString) async {
  final List<ImageWpInfo> imageInfos = [];

  try {
    final document = parse(htmlString);
    final elements = document.getElementsByTagName('img');

    for (var element in elements) {
      final String? src = element.attributes['src'];
      if (src == null || src.isEmpty) continue;

      // ── 1. URL plein format (landscapeUrl) ──────────────────────────────
      // WordPress place un suffixe de taille dans src (ex. -150x150 ou
      // -300x300 selon le réglage "Taille des vignettes" du site, qui a
      // changé au fil du temps) — on le retire par motif pour retrouver
      // l'original, quelle que soit la taille utilisée.
      final String landscapeUrl = stripWpImageSize(src);

      // ── 2. Vignette optimisée ────────────────────────────────────────────
      // -320x320 est la plus grande taille carrée réellement générée par
      // WordPress sur ce site (vérifié : -600x600 n'existe pour aucune
      // image, ancienne ou récente).
      final String thumbnailUrl = insertWpImageSize(landscapeUrl, '-320x320');

      final String fallbackUrl = landscapeUrl;

      // ── 3. Description ──────────────────────────────────────────────────
      final String title = element.attributes['title'] ?? "";
      final String postUrl = _extractPostUrl(landscapeUrl);
      final String description = title.isNotEmpty
          ? "$title\nPost URL: $postUrl"
          : "Post URL: $postUrl";

      imageInfos.add(ImageWpInfo(
        portraitUrl: src,
        thumbnailUrl: thumbnailUrl,
        fallbackUrl: fallbackUrl,
        landscapeUrl: landscapeUrl,
        description: description,
      ));
    }
  } catch (e) {
    return [];
  }

  return imageInfos;
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS PRIVÉS
// ─────────────────────────────────────────────────────────────────────────────

/// Extrait l'URL du dossier parent depuis une URL d'image.
String _extractPostUrl(String imageUrl) {
  if (imageUrl.isEmpty) return "";
  try {
    final uri = Uri.parse(imageUrl);
    final path = uri.path;
    final dir = path.substring(0, path.lastIndexOf('/'));
    return uri.origin + dir;
  } catch (_) {
    return "";
  }
}
