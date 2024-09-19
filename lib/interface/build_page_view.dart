import 'package:flutter/material.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';
import 'package:extended_image/extended_image.dart';
import 'package:spiphoto_app/service/wallpaper_screen.dart'; // Importer le fichier wallpaper_screen.dart

Widget buildPageView(
    BuildContext context, List<ImageWpInfo> imageInfos, int initialIndex) {
  PageController pageController = PageController(
    initialPage: initialIndex,
  );

  // Instance de WallpaperScreen pour gérer les interactions avec MethodChannel
  WallpaperScreen wallpaperScreen = WallpaperScreen();

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
                ],
              );
            },
          ),
        ),
        // Bouton retour
        Positioned(
          top: 16.0,
          left: 16.0,
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        // Bouton flottant pour définir le fond d'écran
        Positioned(
          bottom: 16.0,
          right: 16.0,
          child: FloatingActionButton(
            backgroundColor: Colors.blue,
            onPressed: () {
              // Obtenez l'URL de l'image actuellement affichée
              int currentIndex = pageController.page!.round();
              String currentImageUrl = imageInfos[currentIndex].landscapeUrl;

              // Utiliser la méthode showWallpaperDialog depuis wallpaper_screen.dart
              wallpaperScreen.showWallpaperDialog(context, currentImageUrl);
            },
            child: Icon(Icons.wallpaper, color: Colors.white),
          ),
        ),
      ],
    ),
  );
}
