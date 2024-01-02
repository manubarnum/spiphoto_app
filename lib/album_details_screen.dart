import 'package:flutter/material.dart';
import 'acces_wordpress.dart';

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
            FutureBuilder<List<String>>(
              future: extractImagesFromHtml(album['content']['rendered']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Erreur: ${snapshot.error}');
                } else {
                  List<String>? imageUrls = snapshot.data;

                  if (imageUrls == null || imageUrls.isEmpty) {
                    return Text('Aucune image à afficher.');
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15.0,
                      mainAxisSpacing: 15.0,
                    ),
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        imageUrls[index],
                        fit: BoxFit.cover,
                      );
                    },
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
