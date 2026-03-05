import 'package:flutter/material.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';
import 'package:extended_image/extended_image.dart';
import 'package:spiphoto_app/service/wallpaper_screen.dart';
import 'package:spiphoto_app/service/share_service.dart';

// Fonction de navigation conservée pour compatibilité avec build_grid_view.dart
Widget buildPageView(
    BuildContext context, List<ImageWpInfo> imageInfos, int initialIndex) {
  return PageViewScreen(imageInfos: imageInfos, initialIndex: initialIndex);
}

class PageViewScreen extends StatefulWidget {
  final List<ImageWpInfo> imageInfos;
  final int initialIndex;

  const PageViewScreen({
    Key? key,
    required this.imageInfos,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<PageViewScreen> createState() => _PageViewScreenState();
}

class _PageViewScreenState extends State<PageViewScreen> {
  late PageController _pageController;
  final WallpaperScreen _wallpaperScreen = WallpaperScreen();
  final ShareService _shareService = ShareService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Getter pratique pour l'index courant
  int get _currentIndex => _pageController.hasClients
      ? (_pageController.page?.round() ?? widget.initialIndex)
      : widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;
          final double aspectRatio =
              orientation == Orientation.portrait ? 3 / 2 : 16 / 9;

          return Stack(
            children: [
              SizedBox(
                height: double.infinity,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.imageInfos.length,
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.05,
                              vertical: screenHeight * 0.03,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white,
                                width: 5.0,
                              ),
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            child: AspectRatio(
                              aspectRatio: aspectRatio,
                              child: ExtendedImage.network(
                                widget.imageInfos[index].landscapeUrl,
                                fit: BoxFit.cover,
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

              // Bouton retour
              Positioned(
                top: 16.0,
                left: 16.0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Boutons d'action
              Positioned(
                bottom: screenHeight * 0.05,
                right: screenWidth * 0.05,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: 'wallpaper',
                      backgroundColor: Colors.blue,
                      tooltip: 'Définir comme fond d\'écran',
                      onPressed: () {
                        final String currentImageUrl =
                            widget.imageInfos[_currentIndex].landscapeUrl;
                        // 👈 context passé en paramètre (nouvelle signature)
                        _wallpaperScreen.showWallpaperDialog(
                            context, currentImageUrl);
                      },
                      child: const Icon(Icons.wallpaper, color: Colors.white),
                    ),
                    const SizedBox(height: 16.0),
                    FloatingActionButton(
                      heroTag: 'share',
                      backgroundColor: Colors.pink,
                      tooltip: 'Partager',
                      onPressed: () {
                        final String currentImageUrl =
                            widget.imageInfos[_currentIndex].landscapeUrl;
                        final String currentDescription =
                            widget.imageInfos[_currentIndex].description;
                        _shareService.shareImageOnInstagram(
                            context, currentImageUrl, currentDescription);
                      },
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
}
