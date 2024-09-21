import 'package:flutter/material.dart';
import 'package:spiphoto_app/service/acces_wordpress.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';
import 'package:spiphoto_app/interface/build_grid_view.dart';

class AlbumDetailsScreen extends StatelessWidget {
  final Album album;

  AlbumDetailsScreen({required this.album});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Affichage du titre de l'album
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                album.title, // Affichage du titre de l'album
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // FutureBuilder pour charger et afficher les images de l'album
            FutureBuilder<List<ImageWpInfo>>(
              future: extractImagesFromHtml(album.content['rendered']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Erreur: ${snapshot.error}'),
                  );
                } else {
                  List<ImageWpInfo>? imageInfos = snapshot.data;

                  if (imageInfos == null || imageInfos.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Aucune image à afficher.'),
                    );
                  }

                  // Afficher la grille des images
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: buildGridView(context, imageInfos),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
