import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'album_details_screen.dart';
import 'acces_wordpress.dart';

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
  @override
  void initState() {
    super.initState();
    if (mounted) {
      _loadAlbums(); // Utilisez la fonction pour charger les albums
    }
  }

  Future<void> _loadAlbums() async {
    try {
      await fetchAlbums(); // Utilisez la fonction fetchAlbums depuis le fichier acces_wordpress.dart
      setState(() {
        // Appeler setState si nécessaire
      });
    } catch (e) {
      print('Erreur lors du chargement des albums: $e');
      // Gérer les erreurs si nécessaire
    }
  }

   Future<void> _reload() async {
    try {
      await _loadAlbums();
      setState(() {
        // Mettre à jour l'état si nécessaire
      });
    } catch (e) {
      print('Erreur lors du rechargement des albums: $e');
      // Gérer les erreurs si nécessaire
    }
  }

  @override
  Widget build(BuildContext context) {
    //print('Build called');
    //print('Albums dans le widget: $albums');
    return Scaffold(
       appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 1, 55, 13),
        title: Text('SPIPHOTO'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
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
          ),
          BottomAppBar(
            color: Color.fromARGB(255, 1, 55, 13),
            child: Container(
              height: 50.0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    Uri url = Uri.parse('https://wip.spiphoto.fr/');
                    launchUrl(url);
                  },
                  child: Text(
                    'Retrouvez d\'autres albums sur notre site',
                    style: TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
