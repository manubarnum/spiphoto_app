import 'package:flutter/material.dart';

class MyAppBarAccueil extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBarAccueil({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Color.fromARGB(255, 1, 55, 13),
      leading: Image.asset(
          'android/app/src/main/res/mipmap-xhdpi/rounded_launcher.png'),
      title: Text('SPIPHOTO, l\'application'),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
