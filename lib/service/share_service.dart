import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class ShareService {
  Future<void> shareImageOnInstagram(
      BuildContext context, String imageUrl, String caption) async {
    try {
      // Télécharger l'image depuis l'URL et la stocker localement
      final response = await http.get(Uri.parse(imageUrl));
      final documentDirectory = await getApplicationDocumentsDirectory();
      final file = File('${documentDirectory.path}/temp_image.jpg');
      file.writeAsBytesSync(response.bodyBytes);

      // Vérifier que le widget est toujours monté avant d'utiliser le contexte
      if (!context.mounted) return;

      // Partager l'image avec une légende
      final xFile = XFile(file.path);
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: caption,
        ),
      );
    } catch (e) {
      // Vérifier que le widget est toujours monté avant d'afficher le SnackBar
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du partage de l\'image : $e')),
      );
    }
  }
}
