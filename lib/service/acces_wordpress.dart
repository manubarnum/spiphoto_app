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

  Album({
    required this.content,
    required this.id,
    required this.title,
  }) {
    title = title.replaceAll('&rsquo;', '\u2019');
  }

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      content: json['content'] ?? {},
      id: json['id'] is int ? json['id'] : 0,
      title:
          json['title']['rendered'] is String ? json['title']['rendered'] : '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FETCH ALBUMS
// ─────────────────────────────────────────────────────────────────────────────
Future<List<Album>> fetchAlbums() async {
  final response = await http.get(
    Uri.parse('https://www.spiphoto.fr/wp-json/wp/v2/posts'),
  );

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.map((json) => Album.fromJson(json)).toList();
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
