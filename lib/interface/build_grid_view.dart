import 'package:flutter/material.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';
import 'package:spiphoto_app/interface/build_page_view.dart';

Widget buildGridView(BuildContext context, List<ImageWpInfo> imageInfos) {
  return GridView.builder(
    padding: const EdgeInsets.all(15.0),
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount:
          (MediaQuery.of(context).orientation == Orientation.portrait)
              ? 2
              : 4, // 2 colonnes en portrait, 4 en paysage
      crossAxisSpacing: 13.0,
      mainAxisSpacing: 13.0,
      childAspectRatio: 0.8, // Ajustez cet aspect si nécessaire
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
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color.fromARGB(
                  255, 255, 255, 255), // Couleur de la bordure
              width: 2.0, // Épaisseur de la bordure
            ),
            borderRadius: BorderRadius.circular(10.0), // Bordures arrondies
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: AspectRatio(
              aspectRatio: 1.0, // Proportions carrées des images
              child: Image.network(
                imageInfos[index].portraitUrl,
                fit: BoxFit.cover, // Couvrir l'espace sans déformation
              ),
            ),
          ),
        ),
      );
    },
  );
}
