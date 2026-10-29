import 'dart:io';

import 'package:extended_image/extended_image.dart' show getCachedImageFile;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  /// Ouvre la feuille de partage du système avec l'image et sa légende.
  /// L'image est reprise du cache disque d'ExtendedImage quand elle vient
  /// d'être affichée, et téléchargée sinon. Lève une exception en cas
  /// d'échec : l'affichage du message d'erreur reste à la charge de l'écran
  /// appelant.
  Future<void> shareImage(String imageUrl, String caption) async {
    // Copie sous le nom du fichier d'origine : le fichier du cache n'a pas
    // d'extension, dont les applications destinataires ont besoin. Le dossier
    // est vidé à chaque partage pour ne garder que la dernière image.
    final Directory dossier =
        Directory('${(await getTemporaryDirectory()).path}/partage');
    if (dossier.existsSync()) dossier.deleteSync(recursive: true);
    dossier.createSync();
    final File copie =
        File('${dossier.path}/${Uri.parse(imageUrl).pathSegments.last}');

    final File? enCache = await getCachedImageFile(imageUrl);
    if (enCache != null) {
      await enCache.copy(copie.path);
    } else {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw HttpException(
            'Téléchargement impossible (${response.statusCode})',
            uri: Uri.parse(imageUrl));
      }
      await copie.writeAsBytes(response.bodyBytes);
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(copie.path)],
        text: caption,
      ),
    );
  }
}
