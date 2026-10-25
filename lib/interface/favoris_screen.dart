import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spiphoto_app/spi_colors.dart';
import 'package:spiphoto_app/service/auth_service.dart';
import 'package:spiphoto_app/service/favorites_service.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';
import 'package:spiphoto_app/interface/build_grid_view.dart';
import 'package:spiphoto_app/interface/connexion_requise.dart';

class FavorisScreen extends StatelessWidget {
  const FavorisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder écoute AuthService.authStateChanges : dès que
    // l'utilisateur se connecte ou se déconnecte (depuis n'importe où dans
    // l'app), cet écran se reconstruit automatiquement avec le bon état.
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return const ConnexionRequise(
            icone: Icons.favorite_border,
            titre: 'Mes Favoris',
            message: 'Connectez-vous pour accéder\nà vos photos favorites',
          );
        }
        return _LoggedInView(user: user);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ÉTAT CONNECTÉ
// ─────────────────────────────────────────────────────────────────────────────
class _LoggedInView extends StatelessWidget {
  final User user;
  const _LoggedInView({required this.user});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ImageWpInfo>?>(
      valueListenable: FavoritesService.instance.favoris,
      builder: (context, favoris, _) {
        final bool enChargement = favoris == null;
        final List<ImageWpInfo> photos = favoris ?? const [];

        // Tout défile d'un bloc : compte, titre, puis grille.
        return CustomScrollView(
          slivers: [
            // ── Compte connecté + déconnexion ──────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 4, 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: context.spi.surfaceElevee,
                      backgroundImage: user.photoURL != null
                          ? ExtendedNetworkImageProvider(user.photoURL!,
                              cache: true)
                          : null,
                      child: user.photoURL == null
                          ? Icon(Icons.person,
                              size: 18, color: context.spi.encreSecondaire)
                          : null,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        user.email ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.spi.encreSecondaire,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.logout,
                          color: context.spi.encreSecondaire, size: 20),
                      tooltip: 'Se déconnecter',
                      onPressed: () => AuthService.instance.signOut(),
                    ),
                  ],
                ),
              ),
            ),

            // ── Titre + compteur ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        'Mes favoris',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    if (!enChargement) ...[
                      const SizedBox(width: 12),
                      Text(
                        photos.length > 1
                            ? '${photos.length} photos'
                            : '${photos.length} photo',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.spi.accent,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Filet ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                height: 1,
                color: SpiColors.olive.withValues(alpha: 0.3),
              ),
            ),

            if (enChargement)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: context.spi.mauve),
                ),
              )
            else if (photos.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_border,
                            color: context.spi.encreSecondaire, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun favori pour l\'instant.\nAppuie sur le cœur d\'une photo pour l\'ajouter ici.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              // ── Grille des favoris (temps réel), bordure violette ────
              // Réutilise la grille standard de l'app.
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 24),
                sliver: buildSliverGridView(
                  context,
                  photos,
                  bordure: context.spi.mauve.withValues(alpha: 0.55),
                ),
              ),
          ],
        );
      },
    );
  }
}
