import 'package:flutter/material.dart';
import 'package:spiphoto_app/spi_colors.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';
import 'package:spiphoto_app/interface/build_page_view.dart';

Widget buildGridView(BuildContext context, List<ImageWpInfo> imageInfos) {
  return GridView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount:
          (MediaQuery.of(context).orientation == Orientation.portrait) ? 2 : 4,
      crossAxisSpacing: 15.0,
      mainAxisSpacing: 15.0,
      childAspectRatio: 0.8,
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
              color: SpiColors.olive.withValues(alpha: 0.5),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                spreadRadius: 2,
                blurRadius: 6,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Image.network(
                imageInfos[index].thumbnailUrl, // 600x600 tenté en premier
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
                    // Fallback 320x320 si 600x600 absent
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
        ),
      );
    },
  );
}
