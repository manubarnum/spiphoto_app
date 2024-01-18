import 'package:flutter/material.dart';
import '../acces_wordpress.dart';

class AlbumDetailsScreen extends StatelessWidget {
  final Album album;

  AlbumDetailsScreen({required this.album});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color.fromARGB(255, 101, 2, 151)),
        backgroundColor: const Color.fromARGB(255, 1, 55, 13),
        centerTitle: true,
        title: Text(
          album.title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          Orientation orientation = MediaQuery.of(context).orientation;

          return SingleChildScrollView(
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

                      return (orientation == Orientation.portrait)
                          ? buildGridView(imageInfos)
                          : buildPageView(imageInfos);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildGridView(List<ImageWpInfo> imageInfos) {
    return GridView.builder(
      padding: EdgeInsets.all(15.0),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15.0,
        mainAxisSpacing: 15.0,
        childAspectRatio: 1.3,
      ),
      itemCount: imageInfos.length,
      itemBuilder: (context, index) {
        return Image.network(
          imageInfos[index].portraitUrl,
          fit: BoxFit.cover,
        );
      },
    );
  }

  Widget buildPageView(List<ImageWpInfo> imageInfos) {
    return Container(
      height: 400.0, // Ajustez la hauteur selon vos besoins
      child: PageView.builder(
        itemCount: imageInfos.length,
        itemBuilder: (context, index) {
          return Image.network(
            imageInfos[index].landscapeUrl,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}
