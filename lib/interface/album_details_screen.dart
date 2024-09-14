import 'package:flutter/material.dart';
import 'package:spiphoto_app/acces_wordpress.dart';
import 'package:spiphoto_app/image_wp_info.dart';
import 'package:spiphoto_app/interface/build_grid_view.dart';

class AlbumDetailsScreen extends StatelessWidget {
  final Album album;

  AlbumDetailsScreen({required this.album});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color.fromARGB(255, 23, 0, 34)),
        backgroundColor: const Color.fromARGB(255, 1, 55, 13),
        centerTitle: true,
        title: Text(
          album.title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            FutureBuilder<List<ImageWpInfo>>(
              future: extractImagesFromHtml(album.content['rendered']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Erreur: ${snapshot.error}');
                } else {
                  List<ImageWpInfo>? imageInfos = snapshot.data;

                  if (imageInfos == null || imageInfos.isEmpty) {
                    return Text('Aucune image à afficher.');
                  }

                  return buildGridView(context, imageInfos);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
