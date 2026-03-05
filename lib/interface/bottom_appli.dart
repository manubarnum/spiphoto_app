import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class BottomAppli extends StatelessWidget {
  const BottomAppli({super.key});

  Future<void> _launchURL(BuildContext context) async {
    final Uri url = Uri.parse('https://www.spiphoto.fr/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Remonter l'erreur vers l'UI au lieu d'un throw
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color.fromARGB(255, 23, 146, 50),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.web),
          label: 'Site',
        ),
      ],
      onTap: (index) {
        if (index == 0) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        } else if (index == 1) {
          _launchURL(context); // 👈 context passé en paramètre
        }
      },
    );
  }
}
