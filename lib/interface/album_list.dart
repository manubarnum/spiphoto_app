import 'package:flutter/material.dart';
import '../acces_wordpress.dart';
import 'album_details_screen.dart';

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
          if (snapshot.hasData) {
            final List<Album> albums = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: albums.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 5,
                        margin: EdgeInsets.all(10),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(
                                albums[index].title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    fullscreenDialog: false,
                                    builder: (context) => AlbumDetailsScreen(
                                        album: albums[index]),
                                  ),
                                );
                              },
                            ),
                            // Ajoutez d'autres widgets ici si nécessaire
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          // By default, show a loading spinner.
          return const CircularProgressIndicator();
        },
      ),
    );
  }
}
