import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spiphoto_app/spi_colors.dart';

class MyAppBarAccueil extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBarAccueil({super.key});

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

      // ── Logo à gauche ───────────────────────────────────────────────────
      leading: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Image.asset(
          'assets/icons/mon_logo1.png',
          fit: BoxFit.contain,
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

        // Bouton profil / connexion Google
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: SpiColors.mauveClair, // mauve — distingue le profil
              size: 26,
            ),
            tooltip: 'Mon profil',
            onPressed: () {
              // TODO : ouvrir LoginScreen / ProfileScreen
              // Navigator.pushNamed(context, '/login');
            },
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}
