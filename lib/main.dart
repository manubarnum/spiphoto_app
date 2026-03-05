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
      theme: ThemeData.dark(), // ThemeData.dark() n'est pas const
      title: 'SPIPHOTO, l\'application',
      home: const ScaffoldWithNavigation(),
    );
  }
}

class ScaffoldWithNavigation extends StatelessWidget {
  const ScaffoldWithNavigation({super.key}); // 👈 const ajouté

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MyAppBarAccueil(), // 👈 const ajouté
      body: Navigator(
        onGenerateRoute: (RouteSettings settings) {
          WidgetBuilder builder;
          switch (settings.name) {
            case '/':
              builder = (BuildContext _) => const MyList(); // 👈 const ajouté
              break;
            case '/album_details_screen':
              final album = settings.arguments as Album;
              builder = (BuildContext _) => AlbumDetailsScreen(album: album);
              break;
            default:
              throw Exception('Route non définie : ${settings.name}');
          }
          return MaterialPageRoute(builder: builder, settings: settings);
        },
      ),
      bottomNavigationBar: const BottomAppli(), // 👈 const ajouté
    );
  }
}
