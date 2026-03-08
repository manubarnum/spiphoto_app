import 'package:flutter/material.dart';
import 'package:spiphoto_app/spi_colors.dart';
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

  int get _currentIndex => _pageController.hasClients
      ? (_pageController.page?.round() ?? widget.initialIndex)
      : widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpiColors.noir,
      body: OrientationBuilder(
        builder: (context, orientation) {
          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;
          final double aspectRatio =
              orientation == Orientation.portrait ? 3 / 2 : 16 / 9;

          return Stack(
            children: [
              // ── PageView des photos ──────────────────────────────────────
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
                              // Bordure olive — cohérence palette
                              border: Border.all(
                                color: SpiColors.olive,
                                width: 3.0,
                              ),
                              borderRadius: BorderRadius.circular(15.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(13.0),
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
                                        return Container(
                                          color: SpiColors.surface,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: SpiColors.mauve,
                                            ),
                                          ),
                                        );
                                      case LoadState.completed:
                                        return null;
                                      case LoadState.failed:
                                        return Container(
                                          color: SpiColors.surfaceAlt,
                                          child: const Center(
                                            child: Icon(
                                              Icons.broken_image_outlined,
                                              color: SpiColors.texteMuted,
                                              size: 48,
                                            ),
                                          ),
                                        );
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
                        ),
                      ],
                    );
                  },
                ),
              ),

              // ── Bouton retour ────────────────────────────────────────────
              Positioned(
                top: 16.0,
                left: 16.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: SpiColors.surface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: SpiColors.texte,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),

              // ── Compteur de photos ───────────────────────────────────────
              Positioned(
                top: 24.0,
                right: 16.0,
                child: AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: SpiColors.surface.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.imageInfos.length}',
                        style: const TextStyle(
                          color: SpiColors.texte,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Boutons d'action ─────────────────────────────────────────
              Positioned(
                bottom: screenHeight * 0.05,
                right: screenWidth * 0.05,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fond d'écran
                    FloatingActionButton(
                      heroTag: 'wallpaper',
                      backgroundColor: SpiColors.olive,
                      tooltip: 'Définir comme fond d\'écran',
                      onPressed: () {
                        final String url =
                            widget.imageInfos[_currentIndex].landscapeUrl;
                        _wallpaperScreen.showWallpaperDialog(context, url);
                      },
                      child:
                          const Icon(Icons.wallpaper, color: SpiColors.texte),
                    ),
                    const SizedBox(height: 16.0),
                    // Partager
                    FloatingActionButton(
                      heroTag: 'share',
                      backgroundColor: SpiColors.mauve,
                      tooltip: 'Partager',
                      onPressed: () {
                        final String url =
                            widget.imageInfos[_currentIndex].landscapeUrl;
                        final String desc =
                            widget.imageInfos[_currentIndex].description;
                        _shareService.shareImageOnInstagram(context, url, desc);
                      },
                      child: const Icon(Icons.share, color: SpiColors.texte),
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
