import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spiphoto_app/spi_colors.dart';
import 'package:spiphoto_app/interface/compte_sheet.dart';
import 'package:spiphoto_app/service/auth_service.dart';

class MyAppBarAccueil extends StatelessWidget implements PreferredSizeWidget {
  /// Appelé au tap sur le logo : retour à l'accueil.
  final VoidCallback? onLogoTap;

  /// Appelé depuis le panneau « Mon compte » : ouvre l'onglet Mes favoris.
  final VoidCallback? onMesFavoris;

  const MyAppBarAccueil({super.key, this.onLogoTap, this.onMesFavoris});

  Future<void> _launchSite(BuildContext context) async {
    final Uri url = Uri.parse('https://www.spiphoto.fr/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir le site')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // ── Fond avec légère bordure basse ──────────────────────────────────
      backgroundColor: SpiColors.surface,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: SpiColors.olive
              .withValues(alpha: 0.4), // filet vert olive discret
        ),
      ),

      // ── Logo à gauche — retour à l'accueil ──────────────────────────────
      leading: Tooltip(
        message: 'Accueil',
        child: InkWell(
          onTap: onLogoTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Image.asset(
              'assets/icons/mon_logo1.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),

      // ── Titre centré — style magazine ───────────────────────────────────
      title: const Text(
        'SPIPHOTO',
        style: TextStyle(
          color: SpiColors.texte,
          fontSize: 16.0,
          fontWeight: FontWeight.w800,
          letterSpacing: 4.0,
        ),
      ),
      centerTitle: true,

      // ── Actions à droite ────────────────────────────────────────────────
      actions: [
        // Bouton lien site WordPress
        IconButton(
          icon: const Icon(
            Icons.language,
            color: SpiColors.texte,
            size: 22,
          ),
          tooltip: 'Site SPIPHOTO',
          onPressed: () => _launchSite(context),
        ),

        // Compte : photo Google une fois connecté, pictogramme sinon
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: StreamBuilder<User?>(
            stream: AuthService.instance.authStateChanges,
            initialData: AuthService.instance.currentUser,
            builder: (context, snapshot) {
              final String? photo = snapshot.data?.photoURL;
              return IconButton(
                icon: photo != null
                    ? CircleAvatar(
                        radius: 13,
                        backgroundColor: SpiColors.surfaceHigh,
                        backgroundImage: NetworkImage(photo),
                      )
                    : const Icon(
                        Icons.account_circle_outlined,
                        color:
                            SpiColors.mauveClair, // mauve — distingue le profil
                        size: 26,
                      ),
                tooltip: 'Mon compte',
                onPressed: () =>
                    afficherCompte(context, onMesFavoris: onMesFavoris),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}
