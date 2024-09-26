import 'package:flutter/material.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';
import 'package:extended_image/extended_image.dart';
import 'package:spiphoto_app/service/wallpaper_screen.dart';
import 'package:spiphoto_app/service/share_service.dart'; // Importer le service de partage

Widget buildPageView(
    BuildContext context, List<ImageWpInfo> imageInfos, int initialIndex) {
  PageController pageController = PageController(
    initialPage: initialIndex,
  );

  WallpaperScreen wallpaperScreen = WallpaperScreen();
  ShareService shareService =
      ShareService(); // Créer une instance de ShareService

  return Scaffold(
    body: OrientationBuilder(
      builder: (context, orientation) {
        // Get screen dimensions using MediaQuery for responsive layout
        var screenWidth = MediaQuery.of(context).size.width;
        var screenHeight = MediaQuery.of(context).size.height;

        // Set dynamic aspect ratio based on orientation
        double aspectRatio =
            orientation == Orientation.portrait ? 3 / 2 : 16 / 9;

        return Stack(
          children: [
            Container(
              height: double.infinity,
              child: PageView.builder(
                controller: pageController,
                itemCount: imageInfos.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.symmetric(
                              horizontal:
                                  screenWidth * 0.05, // 5% horizontal margin
                              vertical:
                                  screenHeight * 0.03 // 3% vertical margin
                              ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white,
                              width: 5.0,
                            ),
                            borderRadius: BorderRadius.circular(
                                15.0), // Softer rounded corners
                          ),
                          child: AspectRatio(
                            aspectRatio: aspectRatio,
                            child: ExtendedImage.network(
                              imageInfos[index].landscapeUrl,
                              fit: BoxFit
                                  .cover, // Changed to cover for a more uniform display
                              enableSlideOutPage: true,
                              mode: ExtendedImageMode.gesture,
                              loadStateChanged: (ExtendedImageState state) {
                                switch (state.extendedImageLoadState) {
                                  case LoadState.loading:
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  case LoadState.completed:
                                    return null;
                                  case LoadState.failed:
                                    return const Center(
                                        child: Icon(Icons.error,
                                            color: Colors.red));
                                }
                              },
                              initGestureConfigHandler: (state) =>
                                  GestureConfig(
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
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            // Back button with padding adjustment based on orientation
            Positioned(
              top: 16.0,
              left: 16.0,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            // Column for two Floating Action Buttons
            Positioned(
              bottom: screenHeight * 0.05, // Adjusted based on screen height
              right: screenWidth * 0.05, // Adjusted based on screen width
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    backgroundColor: Colors.blue,
                    onPressed: () {
                      int currentIndex =
                          pageController.page?.round() ?? initialIndex;
                      String currentImageUrl =
                          imageInfos[currentIndex].landscapeUrl;

                      wallpaperScreen.showWallpaperDialog(
                          context, currentImageUrl);
                    },
                    tooltip: 'Définir comme fond d\'écran',
                    child: const Icon(Icons.wallpaper, color: Colors.white),
                  ),
                  const SizedBox(height: 16.0), // Space between the buttons
                  FloatingActionButton(
                    backgroundColor: Colors.pink,
                    onPressed: () {
                      int currentIndex =
                          pageController.page?.round() ?? initialIndex;
                      String currentImageUrl =
                          imageInfos[currentIndex].landscapeUrl;
                      String currentDescription =
                          imageInfos[currentIndex].description;
                      print('Current Description: $currentDescription');

                      // Utiliser le service de partage pour partager sur Instagram
                      shareService.shareImageOnInstagram(
                          context, currentImageUrl, currentDescription);
                    },
                    tooltip: 'Partager sur Instagram',
                    child: const Icon(Icons.share, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}
