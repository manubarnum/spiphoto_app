import 'package:flutter/material.dart';
import '/interface/bottom_appli.dart';
import '/interface/album_list.dart';
import '/interface/appbar_accueil.dart';
import '/interface/album_details_screen.dart';
import 'package:spiphoto_app/service/acces_wordpress.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      title: 'SPIPHOTO, l\'application',
      home: ScaffoldWithNavigation(),
    );
  }
}

class ScaffoldWithNavigation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBarAccueil(),
      body: Navigator(
        onGenerateRoute: (RouteSettings settings) {
          WidgetBuilder builder;
          switch (settings.name) {
            case '/':
              builder = (BuildContext _) => MyList(); // Liste des articles
              break;
            case '/album_details_screen':
              // Récupérer les arguments passés lors de la navigation
              final album = settings.arguments as Album;
              builder = (BuildContext _) =>
                  AlbumDetailsScreen(album: album); // Passer l'album
              break;
            default:
              throw Exception('Route non définie : ${settings.name}');
          }
          return MaterialPageRoute(builder: builder, settings: settings);
        },
      ),
      bottomNavigationBar: BottomAppli(),
    );
  }
}
