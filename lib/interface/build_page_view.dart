import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spiphoto_app/spi_colors.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';
import 'package:extended_image/extended_image.dart';
import 'package:spiphoto_app/interface/wallpaper_preview_screen.dart';
import 'package:spiphoto_app/service/share_service.dart';
import 'package:spiphoto_app/service/auth_service.dart';
import 'package:spiphoto_app/service/favorites_service.dart';

// Fonction de navigation conservée pour la compatibilité avec build_grid_view.dart
Widget buildPageView(
  BuildContext context,
  List<ImageWpInfo> imageInfos,
  int initialIndex, {
  String? legende,
  String? auteur,
}) {
  return PageViewScreen(
    imageInfos: imageInfos,
    initialIndex: initialIndex,
    legende: legende,
    auteur: auteur,
  );
}

/// Visionneuse plein écran : photo au format 2/3, voile de lisibilité,
/// légende + auteur, barre d'actions (fond d'écran, favori, partage) et
/// indicateurs de page.
class PageViewScreen extends StatefulWidget {
  final List<ImageWpInfo> imageInfos;
  final int initialIndex;

  /// Texte affiché sous la photo. Les images WordPress du site n'ont ni
  /// titre ni légende : on y passe le titre de l'album quand il est connu.
  final String? legende;
  final String? auteur;

  const PageViewScreen({
    Key? key,
    required this.imageInfos,
    required this.initialIndex,
    this.legende,
    this.auteur,
  }) : super(key: key);

  @override
  State<PageViewScreen> createState() => _PageViewScreenState();
}

class _PageViewScreenState extends State<PageViewScreen> {
  late final ExtendedPageController _pageController;
  // Photo affichée. Un glissement ne reconstruit que ce qui en dépend
  // (compteur, légende, cœur, indicateurs), pas le PageView ni le voile.
  late final ValueNotifier<int> _index;
  final ShareService _shareService = ShareService();

  // Identifiants des favoris de l'utilisateur connecté — tenu à jour en temps réel
  // pour que le cœur reflète l'état réel même si le favori a été modifié
  // depuis un autre écran (ex. retiré depuis l'onglet Mes Favoris).
  Set<String> _favoris = {};
  final ValueListenable<List<ImageWpInfo>?> _favorisPartages =
      FavoritesService.instance.favoris;

  @override
  void initState() {
    super.initState();
    _index = ValueNotifier(widget.initialIndex);
    _pageController = ExtendedPageController(initialPage: widget.initialIndex);
    _favoris = _idsFavoris();
    _favorisPartages.addListener(_majFavoris);
  }

  Set<String> _idsFavoris() => (_favorisPartages.value ?? const <ImageWpInfo>[])
      .map((p) => p.mediaId)
      .whereType<String>()
      .toSet();

  void _majFavoris() => setState(() => _favoris = _idsFavoris());

  @override
  void dispose() {
    _pageController.dispose();
    _index.dispose();
    _favorisPartages.removeListener(_majFavoris);
    super.dispose();
  }

  ImageWpInfo get _photo => widget.imageInfos[_index.value];

  Future<void> _toggleFavorite() async {
    if (AuthService.instance.currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Connecte-toi depuis l\'onglet Mes Favoris pour ajouter des photos à tes favoris.',
          ),
        ),
      );
      return;
    }

    await FavoritesService.instance.toggleFavorite(
        _photo, _favoris.contains(_photo.mediaId),
        albumTitle: _legende);
  }

  // La légende reprend le titre de l'album : celui de l'écran album, sinon
  // celui porté par la photo (fil du Club), sinon rien (Mes favoris).
  String? get _legende => widget.legende ?? _photo.album;

  Future<void> _partager() async {
    final ScaffoldMessengerState messager = ScaffoldMessenger.of(context);
    try {
      // La taille écran, celle affichée : elle est déjà dans le cache disque.
      await _shareService.shareImage(_photo.ecranUrl, _photo.description);
    } catch (e) {
      messager.showSnackBar(
        SnackBar(content: Text('Erreur lors du partage de l\'image : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écran toujours sombre (centré sur la photo), quel que soit le thème :
    // icônes claires dans la barre d'état.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: SpiColors.noir,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Photos ─────────────────────────────────────────────────────
            ExtendedImageGesturePageView.builder(
              controller: _pageController,
              itemCount: widget.imageInfos.length,
              onPageChanged: (index) => _index.value = index,
              itemBuilder: (context, index) => Center(
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child:
                      _PhotoPleinCadre(url: widget.imageInfos[index].ecranUrl),
                ),
              ),
            ),

            // ── Voile de lisibilité (laisse passer les gestes) ─────────────
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.22, 0.55, 1.0],
                    colors: [
                      SpiColors.noir.withValues(alpha: 0.7),
                      SpiColors.noir.withValues(alpha: 0.0),
                      SpiColors.noir.withValues(alpha: 0.0),
                      SpiColors.noir.withValues(alpha: 0.96),
                    ],
                  ),
                ),
              ),
            ),

            ValueListenableBuilder<int>(
              valueListenable: _index,
              builder: (context, index, _) => SafeArea(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ── Haut : retour + compteur ───────────────────────────
                    Positioned(
                      top: 14,
                      left: 14,
                      right: 14,
                      child: Row(
                        children: [
                          Material(
                            color: SpiColors.surface.withValues(alpha: 0.65),
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => Navigator.pop(context),
                              child: const SizedBox.square(
                                dimension: 40,
                                child: Icon(
                                  Icons.arrow_back_ios_new,
                                  color: SpiColors.texte,
                                  size: 20,
                                  semanticLabel: 'Retour',
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 7),
                            decoration: BoxDecoration(
                              color: SpiColors.surface.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${index + 1} / ${widget.imageInfos.length}',
                              style: const TextStyle(
                                color: SpiColors.texte,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Bas : légende, auteur, actions, pagination ─────────
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_legende != null)
                              Text(
                                _legende!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: SpiColors.texte,
                                  fontSize: 15,
                                  height: 1.45,
                                ),
                              ),
                            if (widget.auteur != null) ...[
                              const SizedBox(height: 9),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: SpiColors.mauve,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.auteur!.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: SpiColors.mauveClair,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 20),
                            _BarreActions(
                              isFav: _favoris.contains(_photo.mediaId),
                              onFondEcran: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WallpaperPreviewScreen(
                                      imageUrl: _photo.landscapeUrl),
                                ),
                              ),
                              // Sans identifiant WordPress, pas de favori.
                              onFavori: _photo.mediaId == null
                                  ? null
                                  : _toggleFavorite,
                              onPartager: _partager,
                            ),
                            if (widget.imageInfos.length > 1) ...[
                              const SizedBox(height: 16),
                              _IndicateursPage(
                                index: index,
                                total: widget.imageInfos.length,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PHOTO PLEIN CADRE — zoom au pincement
// ─────────────────────────────────────────────────────────────────────────────
class _PhotoPleinCadre extends StatelessWidget {
  final String url;

  const _PhotoPleinCadre({required this.url});

  @override
  Widget build(BuildContext context) {
    return ExtendedImage.network(
      url,
      fit: BoxFit.cover,
      mode: ExtendedImageMode.gesture,
      // Double-tap : x2 centré sur le point touché, ou retour à l'échelle 1.
      onDoubleTap: (ExtendedImageGestureState state) {
        final double echelle = state.gestureDetails?.totalScale ?? 1.0;
        state.handleDoubleTap(
          scale: echelle > 1.0 ? 1.0 : 2.0,
          doubleTapPosition: state.pointerDownPosition,
        );
      },
      loadStateChanged: (ExtendedImageState state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            return const ColoredBox(
              color: SpiColors.surface,
              child: Center(
                child: CircularProgressIndicator(color: SpiColors.mauve),
              ),
            );
          case LoadState.completed:
            return null;
          case LoadState.failed:
            return const ColoredBox(
              color: SpiColors.surfaceAlt,
              child: Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: SpiColors.texteMuted,
                  size: 48,
                ),
              ),
            );
        }
      },
      initGestureConfigHandler: (state) => GestureConfig(
        minScale: 1.0,
        animationMinScale: 0.8,
        maxScale: 3.0,
        animationMaxScale: 3.5,
        speed: 1.0,
        inertialSpeed: 100.0,
        initialScale: 1.0,
        inPageView: true,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BARRE D'ACTIONS — remplace les FAB empilés
// ─────────────────────────────────────────────────────────────────────────────
class _BarreActions extends StatelessWidget {
  final bool isFav;
  final VoidCallback onFondEcran;

  /// null : pas de bouton favori (photo sans identifiant WordPress).
  final VoidCallback? onFavori;
  final VoidCallback onPartager;

  const _BarreActions({
    required this.isFav,
    required this.onFondEcran,
    required this.onFavori,
    required this.onPartager,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: SpiColors.surface.withValues(alpha: 0.85),
        border: Border.all(color: SpiColors.olive.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _BoutonAction(
              couleurFond: SpiColors.olive,
              onTap: onFondEcran,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wallpaper, color: SpiColors.texte, size: 21),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Fond d\'écran',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: SpiColors.texte,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onFavori != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: _BoutonAction(
                tooltip: isFav ? 'Retirer des favoris' : 'Ajouter aux favoris',
                onTap: onFavori!,
                child: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: SpiColors.mauveClair,
                  size: 23,
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          Expanded(
            child: _BoutonAction(
              tooltip: 'Partager',
              onTap: onPartager,
              child: const Icon(Icons.share, color: SpiColors.texte, size: 23),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoutonAction extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color couleurFond;
  final String? tooltip;

  const _BoutonAction({
    required this.child,
    required this.onTap,
    this.couleurFond = Colors.transparent,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final Widget bouton = Material(
      color: couleurFond,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        // État pressé de l'olive (#5E7029) ; voile discret sinon.
        highlightColor: couleurFond == SpiColors.olive
            ? SpiColors.oliveClair
            : SpiColors.texte.withValues(alpha: 0.08),
        child: SizedBox(height: 48, child: Center(child: child)),
      ),
    );
    return tooltip == null ? bouton : Tooltip(message: tooltip!, child: bouton);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INDICATEURS DE PAGE — fenêtre de 7 points au plus autour de la photo
// courante (un album peut compter une centaine de photos)
// ─────────────────────────────────────────────────────────────────────────────
class _IndicateursPage extends StatelessWidget {
  final int index;
  final int total;

  const _IndicateursPage({required this.index, required this.total});

  static const int _maxPoints = 7;

  @override
  Widget build(BuildContext context) {
    final int debut = (index - _maxPoints ~/ 2)
        .clamp(0, (total - _maxPoints).clamp(0, total));
    final int fin = (debut + _maxPoints).clamp(0, total);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = debut; i < fin; i++)
          Container(
            width: i == index ? 18 : 5,
            height: 5,
            margin: EdgeInsets.only(left: i == debut ? 0 : 5),
            decoration: BoxDecoration(
              color: i == index ? SpiColors.mauve : SpiColors.texteTertiaire,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}
