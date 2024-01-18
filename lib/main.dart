import 'package:flutter/material.dart';
import 'interface/bottom_appli.dart';
import '/interface/album_list.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      title: 'SPIPHOTO, l\'application',
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 1, 55, 13),
          leading: Image.asset(
              'android/app/src/main/res/mipmap-xhdpi/rounded_launcher.png'),
          title: Text('SPIPHOTO, l\'application'),
        ),
        body: MyList(),
        bottomNavigationBar: BottomAppli(),
      ),
    );
  }
}
