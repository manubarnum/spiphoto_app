import 'package:flutter/material.dart';
import 'package:spiphoto_app/service/acces_wordpress.dart'; // Assure-toi que l'importation des services est correcte
import 'package:spiphoto_app/service/image_wp_info.dart';

class MyList extends StatefulWidget {
  const MyList({Key? key}) : super(key: key);

  @override
  _MyListState createState() => _MyListState();
}

class _MyListState extends State<MyList> {
  late Future<List<Album>> futureAlbums;
  late Future<List<ImageWpInfo>> futureImages;

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
            return const CircularProgressIndicator();
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
                return FutureBuilder<List<ImageWpInfo>>(
                  future: extractImagesFromHtml(albums[index].content[
                      'rendered']), // Assuming the HTML is stored in album.contentetc
                  builder: (context, imageSnapshot) {
                    if (imageSnapshot.hasData &&
                        imageSnapshot.data!.isNotEmpty) {
                      final String imageUrl =
                          imageSnapshot.data!.first.portraitUrl;

                      return Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        margin: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 20.0,
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              imageUrl, // La première image récupérée
                              width: 50.0,
                              height: 50.0,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                Icons.broken_image,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                          title: Text(
                            albums[index].title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: Offset(1.0, 1.0),
                                  blurRadius: 2.0,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/album_details_screen',
                              arguments: albums[index],
                            );
                          },
                        ),
                      );
                    } else {
                      return Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        margin: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 20.0,
                        ),
                        child: ListTile(
                          title: Text(
                            albums[index].title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: Offset(1.0, 1.0),
                                  blurRadius: 2.0,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/album_details_screen',
                              arguments: albums[index],
                            );
                          },
                        ),
                      );
                    }
                  },
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
