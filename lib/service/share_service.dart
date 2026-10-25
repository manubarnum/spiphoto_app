import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class ShareService {
  /// Télécharge l'image puis ouvre la feuille de partage du système avec la
  /// légende. Lève une exception en cas d'échec : l'affichage du message
  /// d'erreur reste à la charge de l'écran appelant.
  Future<void> shareImage(String imageUrl, String caption) async {
    // Télécharger l'image depuis l'URL et la stocker localement
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode != 200) {
      throw HttpException('Téléchargement impossible (${response.statusCode})',
          uri: Uri.parse(imageUrl));
    }
    final documentDirectory = await getApplicationDocumentsDirectory();
    final file = File('${documentDirectory.path}/temp_image.jpg');
    await file.writeAsBytes(response.bodyBytes);

    // Partager l'image avec une légende
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: caption,
      ),
    );
  }
}
