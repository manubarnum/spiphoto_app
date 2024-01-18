import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class BottomAppli extends StatelessWidget {
  const BottomAppli({super.key});
  @override
  Widget build(context) {
    return BottomAppBar(
      color: Color.fromARGB(255, 1, 55, 13),
      child: Container(
        height: 50.0,
        child: Center(
          child: GestureDetector(
            onTap: () {
              Uri url = Uri.parse('https://www.spiphoto.fr/');
              launchUrl(url);
            },
            child: Text(
              'Retrouvez d\'autres albums sur notre site',
              style: TextStyle(
                color: Colors.white,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
