import 'package:flutter/material.dart';
import 'package:spiphoto_app/spi_colors.dart';
import 'package:spiphoto_app/service/acces_wordpress.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';

class MyList extends StatefulWidget {
  const MyList({Key? key}) : super(key: key);

  @override
  _MyListState createState() => _MyListState();
}

class _MyListState extends State<MyList> {
  late Future<List<Album>> futureAlbums;
  final Map<int, Future<List<ImageWpInfo>>> _imageCache = {};

  @override
  void initState() {
    super.initState();
    futureAlbums = fetchAlbums();
  }

  Future<List<ImageWpInfo>> _getImagesForAlbum(Album album) {
    return _imageCache.putIfAbsent(
      album.id,
      () => extractImagesFromHtml(album.content['rendered']),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Album>>(
      future: futureAlbums,
      builder: (context, snapshot) {
        // ── Chargement ──────────────────────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // ── Erreur ──────────────────────────────────────────────────────
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off,
                      color: SpiColors.texteMuted, size: 56),
                  const SizedBox(height: 20),
                  Text('Impossible de charger les albums',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Vérifiez votre connexion',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => futureAlbums = fetchAlbums()),
                    icon: const Icon(Icons.refresh, color: SpiColors.mauve),
                    label: const Text('Réessayer',
                        style: TextStyle(color: SpiColors.mauve)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: SpiColors.mauve),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ── Aucun album ─────────────────────────────────────────────────
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text('Aucun album disponible.',
                style: Theme.of(context).textTheme.bodyMedium),
          );
        }

        final List<Album> albums = snapshot.data!;

        // ── Liste magazine ───────────────────────────────────────────────
        return RefreshIndicator(
          color: SpiColors.mauve,
          backgroundColor: SpiColors.surface,
          onRefresh: () async => setState(() => futureAlbums = fetchAlbums()),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              return FutureBuilder<List<ImageWpInfo>>(
                future: _getImagesForAlbum(albums[index]),
                builder: (context, imageSnapshot) {
                  final String? imageUrl =
                      (imageSnapshot.hasData && imageSnapshot.data!.isNotEmpty)
                          ? imageSnapshot.data!.first.thumbnailUrl
                          : null;

                  final String? fallbackUrl =
                      (imageSnapshot.hasData && imageSnapshot.data!.isNotEmpty)
                          ? imageSnapshot.data!.first.fallbackUrl
                          : null;

                  return _AlbumCardMagazine(
                    album: albums[index],
                    imageUrl: imageUrl,
                    fallbackUrl: fallbackUrl,
                    isLoading: imageSnapshot.connectionState ==
                        ConnectionState.waiting,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARTE MAGAZINE — grande image immersive avec titre en overlay
// ─────────────────────────────────────────────────────────────────────────────
class _AlbumCardMagazine extends StatelessWidget {
  final Album album;
  final String? imageUrl;
  final String? fallbackUrl;
  final bool isLoading;

  const _AlbumCardMagazine({
    required this.album,
    required this.isLoading,
    this.imageUrl,
    this.fallbackUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/album_details_screen',
        arguments: album,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: SpiColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Image de couverture ────────────────────────────────────
              if (imageUrl != null)
                Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: SpiColors.surface,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (_, __, ___) => fallbackUrl != null
                      ? Image.network(
                          fallbackUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _PlaceholderImage(),
                        )
                      : _PlaceholderImage(),
                )
              else if (isLoading)
                Container(
                  color: SpiColors.surface,
                  child: const Center(child: CircularProgressIndicator()),
                )
              else
                _PlaceholderImage(),

              // ── Gradient overlay bas ───────────────────────────────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.35, 1.0],
                      colors: [
                        Colors.transparent,
                        SpiColors.noir.withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Filet accent olive en haut ─────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  color: SpiColors.olive,
                ),
              ),

              // ── Titre + métadonnées en bas ─────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        album.title.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SpiColors.texte,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Point accent mauve
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: SpiColors.mauve,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SPIPHOTO',
                            style: const TextStyle(
                              color: SpiColors.mauveClair,
                              fontSize: 10.0,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const Spacer(),
                          // Icône "voir"
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: SpiColors.texteMuted,
                            size: 12,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLACEHOLDER — quand pas d'image disponible
// ─────────────────────────────────────────────────────────────────────────────
class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: SpiColors.surfaceAlt,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.photo_library_outlined,
                color: SpiColors.texteMuted, size: 40),
            SizedBox(height: 8),
            Text('Album',
                style: TextStyle(
                    color: SpiColors.texteDisable,
                    fontSize: 12,
                    letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }
}
