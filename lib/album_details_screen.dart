import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class AlbumDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> album;

  AlbumDetailsScreen({required this.album});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            AppBar(
              title: Text(
                album['title']['rendered'],
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Html(
              data: album['content']['rendered'],
              //onLinkTap: (url) {
              //  // Gérer le clic sur un lien si nécessaire
              //},
              //  style: {
              //    'img': Style(
              //     margin: EdgeInsets.symmetric(vertical: 10),
              //  ),
              // },
            ),
            // Ajoutez d'autres détails de l'album selon votre structure de données
          ],
        ),
      ),
    );
  }
}
