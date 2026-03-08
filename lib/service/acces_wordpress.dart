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
      // WordPress place des vignettes 150x150 dans src — on retire le suffixe
      final String landscapeUrl =
          src.contains('-150x150') ? src.replaceAll('-150x150', '') : src;

      // ── 2. Vignette optimisée ────────────────────────────────────────────
      // On reconstruit manuellement l'URL 600x600 depuis le src 150x150.
      // Si WordPress ne l'a pas générée, le errorBuilder dans Image.network
      // affichera le fallbackUrl 320x320 (garanti présent dans le srcset).
      final String thumbnailUrl = src.contains('-150x150')
          ? src.replaceAll('-150x150', '-600x600')
          : src;

      final String fallbackUrl = src.contains('-150x150')
          ? src.replaceAll('-150x150', '-320x320')
          : src;

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
