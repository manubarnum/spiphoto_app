import 'package:flutter/material.dart';
import 'album_details_screen.dart';
import 'acces_wordpress.dart'; // Importer le fichier avec les fonctions

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
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
  //List<Map<String, dynamic>> albums = [];

  @override
  void initState() {
    super.initState();
    fetchAlbums(); // Utilisez la fonction fetchAlbums depuis le fichier acces_wordpress.dart
  }

  @override
  Widget build(BuildContext context) {
    //print('Albums dans le widget: $albums');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 1, 55, 13),
        title: Text('10 derniers Albums Photo WordPress'),
      ),
      body: ListView.builder(
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final album = albums[index];
          final title = album['title']['rendered'];
          return ListTile(
            title: Text(
              title != null ? title : 'Titre non disponible',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            onTap: () {
              // Naviguer vers la page de détails de l'album
              Navigator.push(
                context,
                MaterialPageRoute(
                  fullscreenDialog: false,
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
