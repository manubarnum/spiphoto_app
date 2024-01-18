import 'package:flutter/material.dart';
import 'acces_wordpress.dart';
import 'interface/album_details_screen.dart';
import 'interface/bottom_appli.dart';
//import 'dart:io';

/* class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  //HttpClient()..badCertificateCallback = (cert, host, port) => true;
  runApp(MyApp());
} */

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
                return Column(children: [
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
                  BottomAppli()
                ]);
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
