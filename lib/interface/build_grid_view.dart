import 'package:flutter/material.dart';
import '../image_wp_info.dart';
import 'build_page_view.dart';

Widget buildGridView(BuildContext context, List<ImageWpInfo> imageInfos) {
  return GridView.builder(
    padding: EdgeInsets.all(15.0),
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount:
          (MediaQuery.of(context).orientation == Orientation.portrait) ? 2 : 4,
      crossAxisSpacing: 15.0,
      mainAxisSpacing: 15.0,
      childAspectRatio: 1.3,
    ),
    itemCount: imageInfos.length,
    itemBuilder: (context, index) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => buildPageView(context, imageInfos, index),
            ),
          );
        },
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Color.fromARGB(
                      255, 255, 255, 255), // Couleur de la bordure
                  width: 3.0, // Épaisseur de la bordure
                ),
                borderRadius:
                    BorderRadius.circular(10.0), // Rayon des coins du Container
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(8.0), // Rayon des coins de l'image
                child: Image.network(
                  imageInfos[index].portraitUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Ajouter l'adresse de l'image en dessous
            /* Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                imageInfos[index].portraitUrl, // Afficher l'URL de l'image
                style: TextStyle(color: Colors.white, fontSize: 12.0),
                textAlign: TextAlign.center,
              ),
            ), */
          ],
        ),
      );
    },
  );
}
