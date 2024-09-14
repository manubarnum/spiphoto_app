import 'package:flutter/material.dart';
import '../image_wp_info.dart';
import 'package:extended_image/extended_image.dart';

Widget buildPageView(
    BuildContext context, List<ImageWpInfo> imageInfos, int initialIndex) {
  PageController pageController = PageController(
    initialPage: initialIndex,
  );

  return Scaffold(
    body: Stack(
      children: [
        Container(
          height: double.infinity,
          child: PageView.builder(
            controller: pageController,
            itemCount: imageInfos.length,
            itemBuilder: (context, index) {
              return Column(
                children: [
                  Container(
                    margin: EdgeInsets.all(16.0),
                    constraints: BoxConstraints(
                      minHeight: 100,
                      minWidth: 100,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Color.fromARGB(255, 255, 255, 255),
                        width: 5.0,
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ExtendedImage.network(
                      imageInfos[index].landscapeUrl,
                      fit: BoxFit.contain,
                      enableSlideOutPage: true,
                      mode: ExtendedImageMode.gesture,
                      initGestureConfigHandler: (state) => GestureConfig(
                        minScale: 1.0,
                        animationMinScale: 0.8,
                        maxScale: 3.0,
                        animationMaxScale: 3.5,
                        speed: 1.0,
                        inertialSpeed: 100.0,
                        initialScale: 1.0,
                        inPageView: false,
                      ),
                    ),
                  ),
                  // Ajouter l'adresse de l'image en dessous de chaque photo
                  /* Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      imageInfos[index].landscapeUrl,
                      style: TextStyle(color: Colors.white, fontSize: 14.0),
                      textAlign: TextAlign.center,
                    ),
                  ), */
                ],
              );
            },
          ),
        ),
        Positioned(
          top: 16.0,
          left: 16.0,
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context); // Retourne à l'écran précédent
            },
          ),
        ),
      ],
    ),
  );
}
