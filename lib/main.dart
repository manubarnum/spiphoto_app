import 'package:flutter/material.dart';
import 'interface/bottom_appli.dart';
import '/interface/album_list.dart';
import '/interface/appbar_accueil.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      title: 'SPIPHOTO, l\'application',
      home: Scaffold(
        appBar: MyAppBarAccueil(),
        body: MyList(),
        bottomNavigationBar: BottomAppli(),
      ),
    );
  }
}
