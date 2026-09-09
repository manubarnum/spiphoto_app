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
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signInWithGoogle();
      // Si ça réussit, le StreamBuilder parent bascule automatiquement
      // vers _LoggedInView — rien d'autre à faire ici.
    } on AuthDomainException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      debugPrint('DEBUG AUTH ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de la connexion. Réessaie.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border, color: SpiColors.mauve, size: 64),
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
              backgroundColor: SpiColors.mauve,
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
    return Column(
      children: [
        // ── En-tête : compte connecté + déconnexion ──────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: SpiColors.surfaceAlt,
                backgroundImage:
                    user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null
                    ? const Icon(Icons.person,
                        size: 18, color: SpiColors.texteMuted)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  user.email ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: SpiColors.texteMuted),
                tooltip: 'Se déconnecter',
                onPressed: () => AuthService.instance.signOut(),
              ),
            ],
          ),
        ),
        // ── Grille des favoris (temps réel) ───────────────────────────────
        Expanded(
          child: StreamBuilder<List<String>>(
            stream: FavoritesService.instance.watchFavorites(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: SpiColors.mauve),
                );
              }

              final urls = snapshot.data ?? [];
              if (urls.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_border,
                            color: SpiColors.texteMuted, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun favori pour l\'instant.\nAppuie sur le cœur d\'une photo pour l\'ajouter ici.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Reconstruit un ImageWpInfo complet pour chaque URL favorite,
              // puis réutilise la grille standard de l'app (mêmes cartes,
              // mêmes bordures, même navigation vers la visionneuse plein écran).
              final imageInfos =
                  urls.map((url) => ImageWpInfo.fromFavoriteUrl(url)).toList();
              return SingleChildScrollView(
                child: buildGridView(context, imageInfos),
              );
            },
          ),
        ),
      ],
    );
  }
}
