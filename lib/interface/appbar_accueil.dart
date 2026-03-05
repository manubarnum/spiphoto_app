import 'package:flutter/material.dart';

class MyAppBarAccueil extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBarAccueil({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 23, 146, 50),
      elevation: 4.0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          'assets/icons/mon_logo1.png', // 👈 chemin compatible Android ET iOS
        ),
      ),
      title: const Text(
        'SPIPHOTO, l\'application',
        style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
