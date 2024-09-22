import 'package:flutter/material.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';
import 'package:spiphoto_app/interface/build_page_view.dart';

Widget buildGridView(BuildContext context, List<ImageWpInfo> imageInfos) {
  return GridView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount:
          (MediaQuery.of(context).orientation == Orientation.portrait)
              ? 2
              : 4, // 2 colonnes en portrait, 4 en paysage
      crossAxisSpacing: 15.0, // Espacement horizontal entre les images
      mainAxisSpacing: 15.0, // Espacement vertical entre les images
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
              color: Colors.white.withOpacity(
                  0.7), // Bordure blanche avec opacité pour plus de subtilité
              width: 1.5, // Épaisseur réduite de la bordure
            ),
            borderRadius: BorderRadius.circular(
                12.0), // Bords plus arrondis pour un effet plus doux
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2), // Ombre subtile
                spreadRadius: 2,
                blurRadius: 4,
                offset: const Offset(2, 2), // Déplacement de l'ombre
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: AspectRatio(
              aspectRatio: 1.0, // Proportions carrées des images
              child: Image.network(
                imageInfos[index].portraitUrl,
                fit: BoxFit.cover, // Couvrir l'espace sans déformation
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              (loadingProgress.expectedTotalBytes ?? 1)
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error),
              ),
            ),
          ),
        ),
      );
    },
  );
}
