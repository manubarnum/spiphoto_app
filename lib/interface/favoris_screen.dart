import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spiphoto_app/spi_colors.dart';
import 'package:spiphoto_app/service/auth_service.dart';
import 'package:spiphoto_app/service/favorites_service.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';
import 'package:spiphoto_app/interface/build_grid_view.dart';

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
          return _LoggedOutView();
        }
        return _LoggedInView(user: user);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ÉTAT NON CONNECTÉ
// ─────────────────────────────────────────────────────────────────────────────
class _LoggedOutView extends StatefulWidget {
  @override
  State<_LoggedOutView> createState() => _LoggedOutViewState();
}

class _LoggedOutViewState extends State<_LoggedOutView> {
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    final ScaffoldMessengerState messager = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
    // Si ça réussit, le StreamBuilder parent bascule automatiquement
    // vers _LoggedInView — rien d'autre à faire ici.
    final String? erreur = await AuthService.instance.connecterAvecGoogle();
    if (erreur != null) {
      messager.showSnackBar(SnackBar(content: Text(erreur)));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, color: context.spi.mauve, size: 64),
          const SizedBox(height: 20),
          Text(
            'Mes Favoris',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Connectez-vous pour accéder\nà vos photos favorites',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleSignIn,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: SpiColors.texte,
                    ),
                  )
                : const Icon(Icons.login),
            label:
                Text(_isLoading ? 'Connexion...' : 'Se connecter avec Google'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SpiColors.olive,
              foregroundColor: SpiColors.texte,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
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
    return StreamBuilder<List<String>>(
      stream: FavoritesService.instance.watchFavorites(),
      builder: (context, snapshot) {
        final bool enChargement =
            snapshot.connectionState == ConnectionState.waiting;
        final List<String> urls = snapshot.data ?? [];

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
                          ? NetworkImage(user.photoURL!)
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
                        urls.length > 1
                            ? '${urls.length} photos'
                            : '${urls.length} photo',
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
            else if (urls.isEmpty)
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
              // Reconstruit un ImageWpInfo complet pour chaque URL
              // favorite, puis réutilise la grille standard de l'app.
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 24),
                sliver: buildSliverGridView(
                  context,
                  urls.map((url) => ImageWpInfo.fromFavoriteUrl(url)).toList(),
                  bordure: context.spi.mauve.withValues(alpha: 0.55),
                ),
              ),
          ],
        );
      },
    );
  }
}
