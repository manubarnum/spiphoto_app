import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

Future<String> fetchWordPressArticleContent(int postId) async {
  final response = await http.get(
    Uri.parse('https://your-wordpress-site/wp-json/wp/v2/posts/$postId'),
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = json.decode(response.body);
    final String content = data['content']['rendered'];
    return content;
  } else {
    throw Exception('Failed to load post');
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

Future<List<Map<String, dynamic>>> fetchAlbums() async {
  final Uri url = Uri.parse('https://wip.spiphoto.fr/wp-json/wp/v2/posts');

  final response = await http.get(url);

  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(json.decode(response.body));
  } else {
    throw Exception('Failed to load albums');
  }
}
