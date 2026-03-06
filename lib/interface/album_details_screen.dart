import 'package:flutter/material.dart';
import 'package:spiphoto_app/spi_colors.dart';
import 'package:spiphoto_app/service/acces_wordpress.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';
import 'package:spiphoto_app/interface/build_grid_view.dart';

class AlbumDetailsScreen extends StatefulWidget {
  final Album album;

  const AlbumDetailsScreen({Key? key, required this.album}) : super(key: key);

  @override
  State<AlbumDetailsScreen> createState() => _AlbumDetailsScreenState();
}

class _AlbumDetailsScreenState extends State<AlbumDetailsScreen> {
  late Future<List<ImageWpInfo>> _futureImages;

  @override
  void initState() {
    super.initState();
    _futureImages = extractImagesFromHtml(widget.album.content['rendered']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpiColors.noir,

      // ── AppBar locale avec bouton retour ──────────────────────────────
      appBar: AppBar(
        backgroundColor: SpiColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,

        // Bouton retour
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: SpiColors.texte,
          tooltip: 'Retour',
          onPressed: () => Navigator.of(context).pop(),
        ),

        // Titre = nom de l'album, tronqué si trop long
        title: Text(
          widget.album.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: SpiColors.texte,
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
      body: FutureBuilder<List<ImageWpInfo>>(
        future: _futureImages,
        builder: (context, snapshot) {
          // Chargement
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Erreur
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: SpiColors.erreur, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de chargement',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Aucune image
          final List<ImageWpInfo>? imageInfos = snapshot.data;
          if (imageInfos == null || imageInfos.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library_outlined,
                      color: SpiColors.texteMuted, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune image dans cet album',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          // Grille de photos
          return CustomScrollView(
            slivers: [
              // En-tête : titre + nombre de photos
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          widget.album.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${imageInfos.length} photos',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: SpiColors.mauveClair,
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverToBoxAdapter(
                  child: buildGridView(context, imageInfos),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
