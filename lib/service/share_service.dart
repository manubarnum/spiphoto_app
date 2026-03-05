import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class ShareService {
  Future<void> shareImageOnInstagram(
      BuildContext context, String imageUrl, String caption) async {
    try {
      // Téléchargez l'image à partir de l'URL et stockez-la localement
      final response = await http.get(Uri.parse(imageUrl));
      final documentDirectory = await getApplicationDocumentsDirectory();
      final file = File('${documentDirectory.path}/temp_image.jpg');
      file.writeAsBytesSync(response.bodyBytes);

      // Utilisez la méthode `shareXFiles` pour partager l'image avec une légende
      final xFile = XFile(file.path);
      await Share.shareXFiles(
        [xFile],
        text: caption,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du partage de l\'image : $e')),
      );
    }
  }
}
