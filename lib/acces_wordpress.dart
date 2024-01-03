import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

// Appel de la fonction fetchAlbums lors de l'initialisation du widget

List<Map<String, dynamic>> albums = []; // Explicitement typé

Future<void> fetchAlbums() async {
  final Uri url = Uri.parse('https://wip.spiphoto.fr/wp-json/wp/v2/posts');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    albums = List<Map<String, dynamic>>.from(json.decode(response.body));
  } else {
    print('Failed to load albums. Status code: ${response.statusCode}');
    print('Response body: ${response.body}');
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
