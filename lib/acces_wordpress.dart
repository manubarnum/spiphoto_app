import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

//Future<List<Map<String, dynamic>>> fetchAlbums() async {
//  final Uri url = Uri.parse('https://wip.spiphoto.fr/wp-json/wp/v2/posts');

//  final response = await http.get(url);

//  if (response.statusCode == 200) {
//    return List<Map<String, dynamic>>.from(json.decode(response.body));
//  } else {
//    throw Exception('Failed to load albums');
//  }
//}

// Appel de la fonction fetchAlbums lors de l'initialisation du widget

List<Map<String, dynamic>> albums = []; // Explicitement typé

Future<void> fetchAlbums() async {
  final Uri url = Uri.parse('https://wip.spiphoto.fr/wp-json/wp/v2/posts');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    albums = List<Map<String, dynamic>>.from(json.decode(response.body));
    //print('Albums: $albums[]');
  } else {
    throw Exception('Failed to load albums');
  }
}

Future<List<String>> extractImagesFromHtml(String htmlString) async {
  List<String> imageUrls = [];

  var document = parse(htmlString);
  var elements = document.getElementsByTagName('img');

  for (var element in elements) {
    var imageUrl = element.attributes['src'];
    if (imageUrl != null && imageUrl.isNotEmpty) {
      imageUrls.add(imageUrl);
    }
  }

  return Future.value(imageUrls);
}
