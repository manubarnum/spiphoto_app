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
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    if (_loading) {
      return; // Si le chargement est déjà en cours, ne pas le relancer
    }

    try {
      setState(() {
        _loading = true; // Marquer le début du chargement
        print('setState Boucle 1');
      });

      await fetchAlbums();
    } catch (e) {
      print('Erreur lors du chargement des albums: $e');
      // Gérer les erreurs si nécessaire
    } finally {
      if (mounted) {
        // Vérifier si le widget est toujours monté avant d'appeler setState
        setState(() {
          print('setState Boucle 2');
          _loading =
              false; // Marquer la fin du chargement, que ce soit réussi ou non
        });
      }
    }
  }

  Future<void> _reload() async {
    await _loadAlbums();
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
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView.builder(
                    itemCount: albums.length,
                    itemBuilder: (context, index) {
                      final album = albums[index];
                      final title = album['title'];
                      //final content = album['content'];
                      // Ajoutez d'autres champs au besoin

                      return Card(
                        elevation: 5,
                        margin:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                fullscreenDialog: false,
                                builder: (context) => AlbumDetailsScreen(
                                  album: album,
                                  //id: album['id'],
                                  //title: title,
                                  //content: content,
                                  // Passez d'autres champs si nécessaire
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title != null
                                      ? title
                                      : 'Titre non disponible',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                // Add additional information or widgets if needed
                              ],
                            ),
                          ),
                        ),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
