import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'album_details_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WordPress Photo Albums',
      home: PhotoAlbumsScreen(),
    );
  }
}

class PhotoAlbumsScreen extends StatefulWidget {
  @override
  _PhotoAlbumsScreenState createState() => _PhotoAlbumsScreenState();
}

class _PhotoAlbumsScreenState extends State<PhotoAlbumsScreen> {
  List<Map<String, dynamic>> albums = []; // Explicitement typé

  @override
  void initState() {
    super.initState();
    fetchAlbums();
  }

  Future<void> fetchAlbums() async {
    final Uri url = Uri.parse('https://wip.spiphoto.fr/wp-json/wp/v2/posts');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        albums = List<Map<String, dynamic>>.from(json.decode(response.body));
      });
    } else {
      throw Exception('Failed to load albums');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Albums Photo WordPress'),
      ),
      body: ListView.builder(
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final album = albums[index];
          return ListTile(
            title: Text(
              album['title']['rendered'],
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              // Naviguer vers la page de détails de l'album
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlbumDetailsScreen(album: album),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
