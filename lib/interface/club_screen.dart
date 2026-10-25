import 'dart:async';

import 'package:extended_image/extended_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:spiphoto_app/spi_colors.dart';
import 'package:spiphoto_app/service/auth_service.dart';
import 'package:spiphoto_app/service/favorites_service.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';
import 'package:spiphoto_app/interface/build_page_view.dart';
import 'package:spiphoto_app/interface/connexion_requise.dart';
import 'package:spiphoto_app/interface/wallpaper_preview_screen.dart';

/// Le Club : les photos les plus mises en favori par les membres.
/// Réservé aux membres connectés (règles Firestore).
class ClubScreen extends StatelessWidget {
  const ClubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      initialData: AuthService.instance.currentUser,
      builder: (context, snapshot) {
        final User? user = snapshot.data;
        if (user == null) {
          return const ConnexionRequise(
            icone: Icons.groups_outlined,
            titre: 'Le Club',
            message:
                'Connectez-vous pour voir\nles photos préférées des membres',
          );
        }
        return _FilDuClub(key: ValueKey(user.uid));
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIL « LES FAVORIS DU CLUB »
// ─────────────────────────────────────────────────────────────────────────────
class _FilDuClub extends StatefulWidget {
  const _FilDuClub({super.key});

  @override
  State<_FilDuClub> createState() => _FilDuClubState();
}

class _FilDuClubState extends State<_FilDuClub> {
  late Future<List<FavoriClub>> _fil;
  TriClub _tri = TriClub.plusChoisies;

  // Favoris de l'utilisateur, pour l'état du cœur de chaque entrée.
  Set<String> _mesFavoris = {};
  StreamSubscription<List<String>>? _abonnement;

  @override
  void initState() {
    super.initState();
    _fil = FavoritesService.instance.getFavorisDuClub(tri: _tri);
    _abonnement = FavoritesService.instance.watchFavorites().listen((urls) {
      if (mounted) setState(() => _mesFavoris = urls.toSet());
    });
  }

  @override
  void dispose() {
    _abonnement?.cancel();
    super.dispose();
  }

  // Recharge sans vider l'écran : FutureBuilder garde les données
  // précédentes pendant le chargement.
  Future<void> _recharger() {
    final Future<List<FavoriClub>> fil =
        FavoritesService.instance.getFavorisDuClub(tri: _tri);
    setState(() {
      _fil = fil;
    });
    return fil;
  }

  void _changerTri() {
    _tri =
        _tri == TriClub.plusChoisies ? TriClub.dernieres : TriClub.plusChoisies;
    _recharger();
  }

  List<ImageWpInfo> _photos(List<FavoriClub> fil) => fil
      .map((f) => ImageWpInfo.fromFavoriteUrl(f.photoUrl, album: f.albumTitle))
      .toList();

  Future<void> _ouvrir(List<FavoriClub> fil, int index) async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => buildPageView(context, _photos(fil), index),
      ),
    );
    // Des favoris ont pu changer dans la visionneuse.
    if (mounted) _recharger();
  }

  Future<void> _basculerFavori(ImageWpInfo photo) async {
    await FavoritesService.instance.toggleFavorite(
      photo.landscapeUrl,
      _mesFavoris.contains(photo.landscapeUrl),
      albumTitle: photo.album,
    );
    if (mounted) _recharger();
  }

  void _fondEcran(ImageWpInfo photo) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => WallpaperPreviewScreen(imageUrl: photo.landscapeUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FavoriClub>>(
      future: _fil,
      builder: (context, snapshot) {
        final List<FavoriClub>? fil = snapshot.data;

        return RefreshIndicator(
          color: context.spi.mauve,
          backgroundColor: context.spi.surface,
          onRefresh: _recharger,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Titre + filet ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 4, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Le Club',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      // Tri : plus choisies ⇄ dernières ajoutées
                      IconButton(
                        icon: Icon(Icons.sort,
                            color: context.spi.encreSecondaire, size: 22),
                        tooltip: _tri == TriClub.plusChoisies
                            ? 'Voir les dernières ajoutées'
                            : 'Voir les plus choisies',
                        onPressed: _changerTri,
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  height: 1,
                  color: SpiColors.olive.withValues(alpha: 0.3),
                ),
              ),

              // ── Étiquette de section ───────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LES FAVORIS DU CLUB',
                        style: TextStyle(
                          color: context.spi.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _tri == TriClub.plusChoisies
                            ? 'Les photos les plus choisies par les membres'
                            : 'Les dernières photos mises en favori par les membres',
                        style: TextStyle(
                          color: context.spi.encreSecondaire,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (fil == null && snapshot.hasError)
                _message(
                  context,
                  'Impossible de charger le fil du Club.',
                  action: TextButton(
                    onPressed: _recharger,
                    child: Text('Réessayer',
                        style: TextStyle(color: context.spi.mauve)),
                  ),
                )
              else if (fil == null)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (fil.isEmpty)
                _message(context,
                    'Aucune photo n\'a encore été mise en favori\npar les membres.')
              else
                // ── Fil, par nombre de favoris décroissant ─────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: fil.length,
                    separatorBuilder: (_, __) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Container(
                        height: 1,
                        color: SpiColors.olive.withValues(alpha: 0.3),
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final ImageWpInfo photo = _photos(fil)[index];
                      return _EntreeClub(
                        favori: fil[index],
                        photo: photo,
                        estMonFavori: _mesFavoris.contains(photo.landscapeUrl),
                        onOuvrir: () => _ouvrir(fil, index),
                        onFavori: () => _basculerFavori(photo),
                        onFondEcran: () => _fondEcran(photo),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _message(BuildContext context, String texte, {Widget? action}) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                texte,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (action != null) ...[const SizedBox(height: 12), action],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ENTRÉE DU FIL — photo, membres, album et actions
// ─────────────────────────────────────────────────────────────────────────────
class _EntreeClub extends StatelessWidget {
  final FavoriClub favori;
  final ImageWpInfo photo;
  final bool estMonFavori;
  final VoidCallback onOuvrir;
  final VoidCallback onFavori;
  final VoidCallback onFondEcran;

  const _EntreeClub({
    required this.favori,
    required this.photo,
    required this.estMonFavori,
    required this.onOuvrir,
    required this.onFavori,
    required this.onFondEcran,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Photo + pastille du nombre de favoris ────────────────────────
        GestureDetector(
          onTap: onOuvrir,
          child: Container(
            height: 190,
            decoration: BoxDecoration(
              border: Border.all(
                color: context.spi.mauve.withValues(alpha: 0.55),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.5),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Photo(photo: photo),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: SpiColors.noir.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite,
                              color: SpiColors.mauveClair, size: 15),
                          const SizedBox(width: 5),
                          Text(
                            '${favori.nbFavoris}',
                            style: const TextStyle(
                              color: SpiColors.texte,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Membres ──────────────────────────────────────────────────────
        Row(
          children: [
            if (favori.membres.isNotEmpty) ...[
              _PileAvatars(membres: favori.membres.take(3).toList()),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text.rich(
                TextSpan(children: _phrase(context)),
                style: TextStyle(
                  color: context.spi.encreSecondaire,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),

        // ── Album + actions ──────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Text(
                favori.albumTitle != null ? '« ${favori.albumTitle} »' : '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.spi.encreTertiaire,
                  fontSize: 11,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                estMonFavori ? Icons.favorite : Icons.favorite_border,
                color: estMonFavori
                    ? context.spi.accent
                    : context.spi.encreSecondaire,
                size: 20,
              ),
              tooltip:
                  estMonFavori ? 'Retirer des favoris' : 'Ajouter aux favoris',
              onPressed: onFavori,
            ),
            IconButton(
              icon: Icon(Icons.wallpaper,
                  color: context.spi.encreSecondaire, size: 20),
              tooltip: 'Fond d\'écran',
              onPressed: onFondEcran,
            ),
          ],
        ),
      ],
    );
  }

  /// « Claire Vasseur, Marc Lefèvre et 5 autres membres l'ont mise en
  /// favori » — noms en gras ; sans nom connu, seulement le nombre.
  List<InlineSpan> _phrase(BuildContext context) {
    final TextStyle nomStyle = TextStyle(
      color: context.spi.encre,
      fontWeight: FontWeight.w600,
    );
    final List<String> noms = favori.membres.take(2).map((m) => m.nom).toList();
    final int autres = favori.nbFavoris - noms.length;
    final String verbe = favori.nbFavoris > 1
        ? ' l\'ont mise en favori'
        : ' l\'a mise en favori';

    if (noms.isEmpty) {
      return [
        TextSpan(
          text:
              favori.nbFavoris > 1 ? '${favori.nbFavoris} membres' : '1 membre',
        ),
        TextSpan(text: verbe),
      ];
    }

    final List<InlineSpan> spans = [TextSpan(text: noms[0], style: nomStyle)];
    if (noms.length == 2) {
      spans.add(TextSpan(text: autres > 0 ? ', ' : ' et '));
      spans.add(TextSpan(text: noms[1], style: nomStyle));
    }
    if (autres > 0) {
      spans.add(TextSpan(
        text: autres > 1 ? ' et $autres autres membres' : ' et 1 autre membre',
      ));
    }
    spans.add(TextSpan(text: verbe));
    return spans;
  }
}

class _Photo extends StatelessWidget {
  final ImageWpInfo photo;

  const _Photo({required this.photo});

  @override
  Widget build(BuildContext context) {
    // Image plein format décodée à la largeur d'affichage (la vignette
    // 320 px serait floue sur toute la largeur).
    final int largeur = (MediaQuery.sizeOf(context).width *
            MediaQuery.devicePixelRatioOf(context))
        .round();
    final Widget fond = ColoredBox(color: context.spi.surfaceAlt);
    return ExtendedImage.network(
      photo.landscapeUrl,
      fit: BoxFit.cover,
      cacheWidth: largeur,
      loadStateChanged: (state) => switch (state.extendedImageLoadState) {
        LoadState.loading => fond,
        LoadState.completed => null,
        LoadState.failed => ExtendedImage.network(
            photo.thumbnailUrl,
            fit: BoxFit.cover,
            loadStateChanged: (secours) =>
                secours.extendedImageLoadState == LoadState.completed
                    ? null
                    : fond,
          ),
      },
    );
  }
}

/// Avatars superposés (26 px, chevauchement de 9 px, liseré couleur fond).
class _PileAvatars extends StatelessWidget {
  final List<MembreFavori> membres;

  const _PileAvatars({required this.membres});

  @override
  Widget build(BuildContext context) {
    const double taille = 26;
    const double decalage = taille - 9;
    return SizedBox(
      width: taille + (membres.length - 1) * decalage,
      height: taille,
      child: Stack(
        children: [
          for (int i = 0; i < membres.length; i++)
            Positioned(
              left: i * decalage,
              child: Container(
                width: taille,
                height: taille,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.spi.fond, width: 2),
                ),
                child: CircleAvatar(
                  backgroundColor: context.spi.surfaceElevee,
                  backgroundImage: membres[i].photoUrl != null
                      ? ExtendedNetworkImageProvider(membres[i].photoUrl!,
                          cache: true)
                      : null,
                  child: membres[i].photoUrl == null
                      ? Icon(Icons.person,
                          size: 13, color: context.spi.encreSecondaire)
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
