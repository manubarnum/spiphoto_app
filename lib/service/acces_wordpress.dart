import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:spiphoto_app/service/image_wp_info.dart';

class Album {
  final Map<String, dynamic> content;
  final int id;
  String title;

  Album({
    required this.content,
    required this.id,
    required this.title,
  }) {
    // Remplacer les entités HTML dans le titre
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

Future<List<Album>> fetchAlbums() async {
  final response =
      await http.get(Uri.parse('https://www.spiphoto.fr/wp-json/wp/v2/posts'));

  if (response.statusCode == 200) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.map((json) => Album.fromJson(json)).toList();
  } else {
    throw Exception(
        'Impossible de charger les albums (${response.statusCode})');
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
      String postUrl = "";

      if (portraitUrl != null && portraitUrl.contains('-150x150')) {
        landscapeUrl = portraitUrl.replaceAll('-150x150', '');
      } else {
        landscapeUrl = portraitUrl ?? "";
      }

      if (landscapeUrl.isNotEmpty) {
        var uri = Uri.parse(landscapeUrl);
        postUrl = uri.origin + uri.path.substring(0, uri.path.lastIndexOf('/'));
      }

      var description = element.attributes['title'] ?? "";
      description += "\nPost URL: $postUrl";

      imageInfos.add(
        ImageWpInfo(
          portraitUrl: portraitUrl ?? "",
          landscapeUrl: landscapeUrl,
          description: description,
        ),
      );
    }
  } catch (e) {
    return [];
  }

  return imageInfos;
}
