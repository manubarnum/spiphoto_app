import 'package:flutter/material.dart';
import 'package:spiphoto_app/service/acces_wordpress.dart';

class MyList extends StatefulWidget {
  const MyList({Key? key}) : super(key: key);

  @override
  _MyListState createState() => _MyListState();
}

class _MyListState extends State<MyList> {
  late Future<List<Album>> futureAlbums;

  @override
  void initState() {
    super.initState();
    futureAlbums = fetchAlbums();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<List<Album>>(
        future: futureAlbums,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(); // Affiche le spinner de chargement
          } else if (snapshot.hasError) {
            return Text('Erreur: ${snapshot.error}');
          } else if (snapshot.hasData) {
            final List<Album> albums = snapshot.data!;

            if (albums.isEmpty) {
              return const Text('Aucun album disponible.');
            }

            return ListView.builder(
              itemCount: albums.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 5,
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(
                      albums[index].title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    onTap: () {
                      // Utiliser Navigator.pushNamed pour naviguer vers AlbumDetailsScreen
                      Navigator.pushNamed(
                        context,
                        '/album_details_screen',
                        arguments:
                            albums[index], // Passer l'album comme argument
                      );
                    },
                  ),
                );
              },
            );
          }
          return const Text('Aucune donnée disponible.');
        },
      ),
    );
  }
}
