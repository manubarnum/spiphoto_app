import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'acces_wordpress.dart';
import 'album_details_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<List<Album>> futureAlbums;

  @override
  void initState() {
    super.initState();
    futureAlbums = fetchAlbums();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      title: 'SPIPHOTO, l\'application',
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 1, 55, 13),
          title: Text('SPIPHOTO, l\'application'),
        ),
        body: Center(
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
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        fullscreenDialog: false,
                                        builder: (context) =>
                                            AlbumDetailsScreen(
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
                );
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              // By default, show a loading spinner.
              return const CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }
}
