import 'package:flutter/material.dart';
import 'package:spiphoto_app/spi_colors.dart';
import 'package:spiphoto_app/service/acces_wordpress.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';
import 'package:spiphoto_app/interface/build_grid_view.dart';

class AlbumDetailsScreen extends StatelessWidget {
  final Album album;

  const AlbumDetailsScreen({Key? key, required this.album}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<ImageWpInfo> imageInfos = album.images;

    return Scaffold(
      backgroundColor: context.spi.fond,

      // ── AppBar locale avec bouton retour ──────────────────────────────
      appBar: AppBar(
        backgroundColor: context.spi.surface,
        elevation: 0,
        scrolledUnderElevation: 0,

        // Bouton retour
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: context.spi.encre,
          tooltip: 'Retour',
          onPressed: () => Navigator.of(context).pop(),
        ),

        // Titre = nom de l'album, tronqué si trop long
        title: Text(
          album.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.spi.encre,
            fontSize: 15.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,

        // Filet bas identique à l'AppBar principale
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: SpiColors.olive.withValues(alpha: 0.4),
          ),
        ),
      ),

      // ── Corps ─────────────────────────────────────────────────────────
      body: imageInfos.isEmpty
          // Aucune image
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library_outlined,
                      color: context.spi.encreSecondaire, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune image dans cet album',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          // Grille de photos
          : CustomScrollView(
              slivers: [
                // En-tête : titre + nombre de photos
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        // Auteur à la suite du titre, sur la même ligne
                        // de base, en métadonnée discrète.
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: album.title,
                              children: [
                                if (album.authorName != null)
                                  TextSpan(
                                    text: '  par ${album.authorName}',
                                    style: TextStyle(
                                      color: context.spi.encreSecondaire,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                              ],
                            ),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          imageInfos.length > 1
                              ? '${imageInfos.length} photos'
                              : '${imageInfos.length} photo',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: context.spi.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Filet séparateur
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    height: 1,
                    color: SpiColors.olive.withValues(alpha: 0.3),
                  ),
                ),

                // Grille
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(15, 0, 15, 24),
                  sliver: buildSliverGridView(
                    context,
                    imageInfos,
                    legende: album.title,
                    auteur: album.authorName,
                  ),
                ),
              ],
            ),
    );
  }
}
