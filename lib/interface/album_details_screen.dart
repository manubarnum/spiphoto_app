import 'package:flutter/material.dart';
import 'package:spiphoto_app/service/acces_wordpress.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';
import 'package:spiphoto_app/interface/build_grid_view.dart';

class AlbumDetailsScreen extends StatefulWidget {
  final Album album;

  const AlbumDetailsScreen({Key? key, required this.album}) : super(key: key);

  @override
  State<AlbumDetailsScreen> createState() => _AlbumDetailsScreenState();
}

class _AlbumDetailsScreenState extends State<AlbumDetailsScreen> {
  late Future<List<ImageWpInfo>> _futureImages;

  @override
  void initState() {
    super.initState();
    // Future créé une seule fois dans initState() — pas recalculé à chaque rebuild
    _futureImages = extractImagesFromHtml(widget.album.content['rendered']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre de l'album
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.album.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Grille des images
            FutureBuilder<List<ImageWpInfo>>(
              future: _futureImages, // 👈 mis en cache dans initState()
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Erreur: ${snapshot.error}'),
                  );
                } else {
                  final List<ImageWpInfo>? imageInfos = snapshot.data;

                  if (imageInfos == null || imageInfos.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Aucune image à afficher.'),
                    );
                  }

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
