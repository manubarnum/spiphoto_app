import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:spiphoto_app/spi_colors.dart';
import 'package:spiphoto_app/service/auth_service.dart';

/// Ouvre le panneau « Mon compte » depuis l'icône utilisateur de la barre
/// d'accueil. [onMesFavoris] bascule sur l'onglet Mes favoris.
Future<void> afficherCompte(BuildContext context,
    {VoidCallback? onMesFavoris}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: SpiColors.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => _PanneauCompte(onMesFavoris: onMesFavoris),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PANNEAU « MON COMPTE » — suit l'état de connexion en temps réel
// ─────────────────────────────────────────────────────────────────────────────
class _PanneauCompte extends StatefulWidget {
  final VoidCallback? onMesFavoris;

  const _PanneauCompte({this.onMesFavoris});

  @override
  State<_PanneauCompte> createState() => _PanneauCompteState();
}

class _PanneauCompteState extends State<_PanneauCompte> {
  bool _connexionEnCours = false;

  Future<void> _seConnecter() async {
    final ScaffoldMessengerState messager = ScaffoldMessenger.of(context);
    setState(() => _connexionEnCours = true);
    // En cas de succès, le StreamBuilder bascule sur la vue connectée.
    final String? erreur = await AuthService.instance.connecterAvecGoogle();
    if (erreur != null) {
      messager.showSnackBar(SnackBar(content: Text(erreur)));
    }
    if (mounted) setState(() => _connexionEnCours = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: StreamBuilder<User?>(
        stream: AuthService.instance.authStateChanges,
        initialData: AuthService.instance.currentUser,
        builder: (context, snapshot) {
          final User? user = snapshot.data;
          return user == null ? _vueDeconnectee() : _vueConnectee(user);
        },
      ),
    );
  }

  Widget _vueConnectee(User user) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Identité ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: SpiColors.surfaceHigh,
                backgroundImage:
                    user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null
                    ? const Icon(Icons.person,
                        size: 26, color: SpiColors.texteMuted)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? 'Mon compte',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SpiColors.texte,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (user.email != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.email!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SpiColors.texteMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const _Separateur(),
        _LigneCompte(
          icone: Icons.favorite_border,
          libelle: 'Mes favoris',
          onTap: () {
            Navigator.pop(context);
            widget.onMesFavoris?.call();
          },
        ),
        const _Separateur(),
        _LigneCompte(
          icone: Icons.logout,
          libelle: 'Se déconnecter',
          onTap: () {
            Navigator.pop(context);
            AuthService.instance.signOut();
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _vueDeconnectee() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_circle_outlined,
              color: SpiColors.mauveClair, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Mon compte',
            style: TextStyle(
              color: SpiColors.texte,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connectez-vous pour enregistrer vos photos favorites.',
            textAlign: TextAlign.center,
            style: TextStyle(color: SpiColors.texteMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _connexionEnCours ? null : _seConnecter,
              icon: _connexionEnCours
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: SpiColors.texte),
                    )
                  : const Icon(Icons.login),
              label: Text(_connexionEnCours
                  ? 'Connexion...'
                  : 'Se connecter avec Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SpiColors.olive,
                foregroundColor: SpiColors.texte,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LigneCompte extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final VoidCallback onTap;

  const _LigneCompte({
    required this.icone,
    required this.libelle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            Icon(icone, color: SpiColors.texteMuted, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                libelle,
                style: const TextStyle(
                  color: SpiColors.texte,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Separateur extends StatelessWidget {
  const _Separateur();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: SpiColors.surfaceHigh,
    );
  }
}
