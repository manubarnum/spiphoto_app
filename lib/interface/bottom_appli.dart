import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class BottomAppli extends StatelessWidget {
  const BottomAppli({super.key});

  // Fonction pour ouvrir le lien du site
  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://www.spiphoto.fr/');
    if (!await launchUrl(
      url,
      mode: LaunchMode
          .externalApplication, // Ouvre l'URL dans un navigateur externe
    )) {
      throw 'Impossible d\'ouvrir $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: const Color.fromARGB(255, 1, 55, 13),
      child: Container(
        height: 56.0, // Fixer la hauteur du BottomAppBar à 56 pixels
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceAround, // Espacer les icônes
          children: [
            // Icône pour revenir à la page d'accueil
            IconButton(
              icon: const Icon(Icons.home, color: Colors.white),
              onPressed: () {
                // Utilisation de pushNamedAndRemoveUntil pour être sûr de revenir à l'accueil
                Navigator.pushNamedAndRemoveUntil(
                    context, '/', (route) => false);
              },
            ),
            // Icône pour ouvrir le site
            IconButton(
              icon: const Icon(Icons.web, color: Colors.white),
              onPressed: _launchURL,
            ),
          ],
        ),
      ),
    );
  }
}
