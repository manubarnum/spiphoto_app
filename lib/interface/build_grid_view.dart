import 'package:flutter/material.dart';
import 'package:spiphoto_app/spi_colors.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';
import 'package:spiphoto_app/interface/build_page_view.dart';

// Tuiles carrées, 2 colonnes en portrait et 4 en paysage, gouttière 15 px.
SliverGridDelegate _gridDelegate(BuildContext context) {
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount:
        (MediaQuery.of(context).orientation == Orientation.portrait) ? 2 : 4,
    crossAxisSpacing: 15.0,
    mainAxisSpacing: 15.0,
  );
}

Widget buildGridView(BuildContext context, List<ImageWpInfo> imageInfos) {
  return GridView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: _gridDelegate(context),
    itemCount: imageInfos.length,
    itemBuilder: (context, index) =>
        _VignettePhoto(imageInfos: imageInfos, index: index),
  );
}

/// Variante sliver de [buildGridView], à placer dans un CustomScrollView.
/// Les vignettes sont construites à la demande : sur un album d'une
/// centaine de photos, seules celles proches de l'écran sont chargées.
Widget buildSliverGridView(BuildContext context, List<ImageWpInfo> imageInfos) {
  return SliverGrid.builder(
    gridDelegate: _gridDelegate(context),
    itemCount: imageInfos.length,
    itemBuilder: (context, index) =>
        _VignettePhoto(imageInfos: imageInfos, index: index),
  );
}

class _VignettePhoto extends StatelessWidget {
  final List<ImageWpInfo> imageInfos;
  final int index;

  const _VignettePhoto({required this.imageInfos, required this.index});

  @override
  Widget build(BuildContext context) {
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
            color: SpiColors.olive.withValues(alpha: 0.5),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.5),
          child: Image.network(
            imageInfos[index].thumbnailUrl, // vignette 320x320
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: SpiColors.surface,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            (loadingProgress.expectedTotalBytes ?? 1)
                        : null,
                    color: SpiColors.mauve,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) =>
                // Fallback image plein format si la vignette est absente
                Image.network(
              imageInfos[index].fallbackUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: SpiColors.surfaceAlt,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: SpiColors.texteMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
