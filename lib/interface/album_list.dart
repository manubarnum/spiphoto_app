import 'package:flutter/material.dart';
import 'package:extended_image/extended_image.dart';
import 'package:spiphoto_app/spi_colors.dart';
import 'package:spiphoto_app/service/acces_wordpress.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';

/// Écran d'accueil en mosaïque : l'album le plus récent en photo à la une,
/// puis les autres albums par paires dans une grille de deux colonnes.
class MyList extends StatefulWidget {
  const MyList({super.key});

  @override
  _MyListState createState() => _MyListState();
}

class _MyListState extends State<MyList> {
  final List<Album> _albums = [];
  final Set<int> _idsAlbums = {};

  int _total = 0;
  int _pageSuivante = 1;
  bool _finAtteinte = false;

  bool _chargementInitial = true;
  Object? _erreurInitiale;
  bool _chargementSuite = false;
  bool _erreurSuite = false;

  // Incrémenté à chaque rechargement complet : une page demandée avant un
  // rafraîchissement ne doit pas s'ajouter à la liste fraîchement rechargée.
  int _generation = 0;

  // Distance au bas de la grille (px) en deçà de laquelle on charge la suite.
  static const double _seuilChargement = 600;

  @override
  void initState() {
    super.initState();
    _chargerPremierePage();
  }

  /// (Re)charge la première page. Au premier affichage, l'écran montre un
  /// indicateur plein écran ; lors d'un tirer-pour-rafraîchir, la liste
  /// actuelle reste visible et n'est remplacée qu'en cas de succès.
  Future<void> _chargerPremierePage() async {
    final int generation = ++_generation;
    try {
      final PageAlbums page = await fetchAlbums();
      if (!mounted || generation != _generation) return;
      setState(() {
        _albums.clear();
        _idsAlbums.clear();
        _pageSuivante = 1;
        _ajouter(page);
        _erreurInitiale = null;
        _erreurSuite = false;
        _chargementSuite = false;
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      if (_albums.isEmpty) {
        setState(() => _erreurInitiale = e);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de rafraîchir les albums')),
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _chargementInitial = false);
      }
    }
  }

  Future<void> _chargerSuite() async {
    if (_chargementSuite || _finAtteinte || _erreurSuite) return;
    final int generation = _generation;
    setState(() => _chargementSuite = true);
    try {
      final PageAlbums page = await fetchAlbums(page: _pageSuivante);
      if (!mounted || generation != _generation) return;
      setState(() => _ajouter(page));
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() => _erreurSuite = true);
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _chargementSuite = false);
      }
    }
  }

  // Ignore les albums déjà présents : si un article est publié entre deux
  // chargements, les pages se décalent et le dernier album d'une page
  // réapparaît en tête de la suivante.
  void _ajouter(PageAlbums page) {
    for (final Album album in page.albums) {
      if (_idsAlbums.add(album.id)) _albums.add(album);
    }
    _total = page.total;
    _pageSuivante++;
    _finAtteinte = page.albums.isEmpty || _pageSuivante > page.totalPages;
  }

  void _reessayerPremierePage() {
    setState(() {
      _chargementInitial = true;
      _erreurInitiale = null;
    });
    _chargerPremierePage();
  }

  bool _surDefilement(ScrollNotification notification) {
    if (notification.metrics.extentAfter < _seuilChargement) _chargerSuite();
    return false;
  }

  // Navigateur de l'onglet : l'album s'ouvre sous la nav basse.
  void _ouvrirAlbum(Album album) {
    Navigator.pushNamed(context, '/album_details_screen', arguments: album);
  }

  @override
  Widget build(BuildContext context) {
    // ── Chargement ──────────────────────────────────────────────────────
    if (_chargementInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    // ── Erreur ──────────────────────────────────────────────────────────
    if (_erreurInitiale != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off,
                  color: context.spi.encreSecondaire, size: 56),
              const SizedBox(height: 20),
              Text('Impossible de charger les albums',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Vérifiez votre connexion',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _reessayerPremierePage,
                icon: Icon(Icons.refresh, color: context.spi.mauve),
                label: Text('Réessayer',
                    style: TextStyle(color: context.spi.mauve)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.spi.mauve),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Aucun album ─────────────────────────────────────────────────────
    if (_albums.isEmpty) {
      return Center(
        child: Text('Aucun album disponible.',
            style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    final Album aLaUne = _albums.first;
    final List<Album> autres = _albums.skip(1).toList();
    final int nbRangees = (autres.length / 2).ceil();

    // ── Mosaïque ────────────────────────────────────────────────────────
    return RefreshIndicator(
      color: context.spi.mauve,
      backgroundColor: context.spi.surface,
      onRefresh: _chargerPremierePage,
      child: NotificationListener<ScrollNotification>(
        onNotification: _surDefilement,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _PhotoALaUne(
                album: aLaUne,
                onTap: () => _ouvrirAlbum(aLaUne),
              ),
            ),
            SliverToBoxAdapter(
              child: _EnteteSection(nbAlbums: _total),
            ),
            // Une rangée = une paire d'albums. Des Row plutôt qu'une
            // SliverGrid : la hauteur des légendes sous les tuiles varie
            // (titre sur 1 ou 2 lignes, taille de police système).
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: nbRangees,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, rangee) {
                  final Album gauche = autres[rangee * 2];
                  final Album? droite = rangee * 2 + 1 < autres.length
                      ? autres[rangee * 2 + 1]
                      : null;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _tuile(gauche)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: droite != null
                            ? _tuile(droite)
                            : const SizedBox.shrink(),
                      ),
                    ],
                  );
                },
              ),
            ),

            // ── Suite : indicateur, ou relance après erreur ────────────
            if (_chargementSuite)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Center(
                    child: SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              )
            else if (_erreurSuite)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() => _erreurSuite = false);
                        _chargerSuite();
                      },
                      icon: Icon(Icons.refresh, color: context.spi.mauve),
                      label: Text('Charger la suite',
                          style: TextStyle(color: context.spi.mauve)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tuile(Album album) {
    return _TuileAlbum(
      album: album,
      onTap: () => _ouvrirAlbum(album),
    );
  }
}

String _nbPhotos(int n) => n > 1 ? '$n photos' : '$n photo';

// ─────────────────────────────────────────────────────────────────────────────
// PHOTO À LA UNE — album le plus récent, pleine largeur
// ─────────────────────────────────────────────────────────────────────────────
class _PhotoALaUne extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const _PhotoALaUne({
    required this.album,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<ImageWpInfo> photos = album.images;
    final List<String> meta = [
      if (album.authorName != null) 'Album de ${album.authorName}',
      _nbPhotos(photos.length),
    ];

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 300,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Photo ──────────────────────────────────────────────
            // Taille écran (la vignette 320 px serait floue en pleine
            // largeur), décodée à la taille d'affichage.
            if (photos.isNotEmpty)
              _PhotoReseau(
                url: photos.first.ecranUrl,
                urlSecours: photos.first.thumbnailUrl,
                largeurDecodage: (MediaQuery.sizeOf(context).width *
                        MediaQuery.devicePixelRatioOf(context))
                    .round(),
              )
            else
              const _FondPhoto(),

            // ── Dégradé de lisibilité ──────────────────────────────
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.3, 1.0],
                  colors: [
                    SpiColors.noir.withValues(alpha: 0.35),
                    SpiColors.noir.withValues(alpha: 0.0),
                    SpiColors.noir.withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),

            // ── Badge, titre, métadonnées ──────────────────────────
            Positioned(
              left: 20,
              right: 20,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: SpiColors.olive,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'À LA UNE',
                      style: TextStyle(
                        color: SpiColors.texte,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    album.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SpiColors.texte,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      meta.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SpiColors.texteMuted,
                        fontSize: 12,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ENTÊTE DE SECTION — « TOUS LES ALBUMS » + compteur, puis filet
// ─────────────────────────────────────────────────────────────────────────────
class _EnteteSection extends StatelessWidget {
  final int nbAlbums;

  const _EnteteSection({required this.nbAlbums});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'TOUS LES ALBUMS',
                style: TextStyle(
                  color: context.spi.encre,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.4,
                ),
              ),
              Text(
                '$nbAlbums',
                style: TextStyle(
                  color: context.spi.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 1,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          color: SpiColors.olive.withValues(alpha: 0.35),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TUILE D'ALBUM — vignette carrée bordée olive, titre et nombre de photos
// ─────────────────────────────────────────────────────────────────────────────
class _TuileAlbum extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const _TuileAlbum({
    required this.album,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<ImageWpInfo> photos = album.images;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: SpiColors.olive.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.5),
                child: photos.isNotEmpty
                    ? _PhotoReseau(
                        url: photos.first.thumbnailUrl,
                        urlSecours: photos.first.ecranUrl,
                      )
                    : const _FondPhoto(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            album.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.spi.encre,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
          Text(
            _nbPhotos(photos.length),
            style: TextStyle(
              color: context.spi.encreSecondaire,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PHOTO RÉSEAU — fond neutre pendant le chargement, URL de secours en erreur
// ─────────────────────────────────────────────────────────────────────────────
class _PhotoReseau extends StatelessWidget {
  final String url;
  final String urlSecours;
  final int? largeurDecodage;

  const _PhotoReseau({
    required this.url,
    required this.urlSecours,
    this.largeurDecodage,
  });

  @override
  Widget build(BuildContext context) {
    return ExtendedImage.network(
      url,
      fit: BoxFit.cover,
      cacheWidth: largeurDecodage,
      loadStateChanged: (state) => switch (state.extendedImageLoadState) {
        LoadState.loading => const _FondPhoto(),
        LoadState.completed => null,
        LoadState.failed => ExtendedImage.network(
            urlSecours,
            fit: BoxFit.cover,
            cacheWidth: largeurDecodage,
            loadStateChanged: (secours) =>
                switch (secours.extendedImageLoadState) {
              LoadState.loading => const _FondPhoto(),
              LoadState.completed => null,
              LoadState.failed => const _FondPhoto(enErreur: true),
            },
          ),
      },
    );
  }
}

class _FondPhoto extends StatelessWidget {
  final bool enErreur;

  const _FondPhoto({this.enErreur = false});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.spi.surfaceAlt,
      child: enErreur
          ? Center(
              child: Icon(Icons.broken_image_outlined,
                  color: context.spi.encreSecondaire, size: 32),
            )
          : const SizedBox.expand(),
    );
  }
}
