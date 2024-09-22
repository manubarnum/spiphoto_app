import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class BottomAppli extends StatelessWidget {
  const BottomAppli({super.key});

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://www.spiphoto.fr/');
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw 'Impossible d\'ouvrir $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF007A1A), // Vert adouci
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: 'Accueil', // Label sous l'icône
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.web),
          label: 'Site', // Label sous l'icône
        ),
      ],
      onTap: (index) {
        if (index == 0) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        } else if (index == 1) {
          _launchURL();
        }
      },
    );
  }
}
