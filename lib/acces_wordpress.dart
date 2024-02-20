import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'image_wp_info.dart';

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
  final response =
      await http.get(Uri.parse('https://www.spiphoto.fr/wp-json/wp/v2/posts'));

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
      var landscapeUrl = "";

      // Recherche de l'ancêtre <a>
      var anchorElement = element.parent;
      while (anchorElement != null && anchorElement.localName != 'a') {
        anchorElement = anchorElement.parent;
      }

      if (anchorElement != null) {
        // Si une balise <a> est trouvée, récupérer son attribut href
        landscapeUrl = anchorElement.attributes['href'] ?? "";
      }

      // Nouvelle ligne pour extraire la description du texte alternatif (alt)
      var description = element.attributes['title'] ?? "";

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

  // Filtrez les images dès le début
  return imageInfos
      //.where((info) => info.description.toLowerCase() == 'favori')
      .toList();
}
