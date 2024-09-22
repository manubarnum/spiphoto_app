import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:spiphoto_app/service/image_wp_info.dart';

// Appel de la fonction fetchAlbums lors de l'initialisation du widget

List<Map<String, dynamic>> albums = []; // Explicitement typé

class Album {
  final Map<String, dynamic> content;
  final int id;
  String title;

  Album({
    required this.content,
    required this.id,
    required this.title,
  }) {
    // Remplacer les occurrences de '&rsquo;' par '\u2019' dans le titre
    title = title.replaceAll('&rsquo;', '\u2019');
  }
  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      content: json['content'] ?? {}, // Assuming content is a Map
      id: json['id'] is int ? json['id'] : 0,
      title:
          json['title']['rendered'] is String ? json['title']['rendered'] : '',
    );
  }
}

Future<List<Album>> fetchAlbums() async {
  final response = await http.get(
      Uri.parse('https://a6a1-408e804a28c4.wptiger.fr/wp-json/wp/v2/posts'));

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    final List<Album> albums =
        jsonList.map((json) => Album.fromJson(json)).toList();
    return albums;
  } else {
    throw Exception('Failed to load albums, zut!');
  }
}

Future<List<ImageWpInfo>> extractImagesFromHtml(String htmlString) async {
  List<ImageWpInfo> imageInfos = [];

  try {
    var document = parse(htmlString);
    var elements = document.getElementsByTagName('img');

    for (var element in elements) {
      var portraitUrl = element.attributes['src'];
      String landscapeUrl = "";

      if (portraitUrl != null && portraitUrl.contains('-150x150')) {
        // Supprimer la partie '-150x150' pour obtenir l'URL complète
        landscapeUrl = portraitUrl.replaceAll('-150x150', '');
      } else {
        landscapeUrl = portraitUrl ?? ""; // Si aucune modification nécessaire
      }

      // Extraire la description du texte alternatif (title)
      var description = element.attributes['title'] ?? "";

      // Ajouter les informations de l'image à la liste
      imageInfos.add(
        ImageWpInfo(
          portraitUrl: portraitUrl ?? "",
          landscapeUrl: landscapeUrl,
          description: description,
        ),
      );
    }
  } catch (e) {
    print('Erreur de parsing HTML: $e');
    return [];
  }

  return imageInfos;
}
