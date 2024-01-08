import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

// Appel de la fonction fetchAlbums lors de l'initialisation du widget

List<Map<String, dynamic>> albums = []; // Explicitement typé

class Album {
  final Map<String, dynamic> content;
  final int id;
  final String title;

  Album({
    required this.content,
    required this.id,
    required this.title,
  });

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
      await http.get(Uri.parse('https://wip.spiphoto.fr/wp-json/wp/v2/posts'));

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    final List<Album> albums =
        jsonList.map((json) => Album.fromJson(json)).toList();
    return albums;
  } else {
    throw Exception('Failed to load albums');
  }
}

class ImageWpInfo {
  String portraitUrl;
  String landscapeUrl;

  ImageWpInfo({required this.portraitUrl, required this.landscapeUrl});
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

      imageInfos.add(ImageWpInfo(
        portraitUrl: portraitUrl ?? "",
        landscapeUrl: landscapeUrl,
      ));
    }
  } catch (e) {
    print('Erreur de parsing HTML: $e');
    return [];
  }

  return imageInfos;
}
