import 'package:flutter/material.dart';

class MyAppBarAccueil extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBarAccueil({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor:
          const Color.fromARGB(255, 23, 146, 50), // Un vert plus doux
      elevation: 4.0, // Ajout d'une ombre pour un léger effet de profondeur
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          'android/app/src/main/res/mipmap-xhdpi/rounded_launcher.png',
        ),
      ),
      title: const Text(
        'SPIPHOTO, l\'application',
        style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
      ),
      centerTitle: true, // Centrer le titre
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
