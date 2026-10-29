// image_wp_info.dart

/// Dossier des médias du site de production. Les favoris ne stockent que le
/// chemin qui suit `/wp-content/uploads/` : chaque client (app, site local,
/// site de production) y ajoute son propre préfixe.
const String dossierMedias =
    'https://www.spiphoto.fr/wordpress/wp-content/uploads/';

const String _repereMedias = '/wp-content/uploads/';

/// Chemin d'une image relatif au dossier des médias (« 2026/07/photo.jpg »),
/// ou null si l'URL n'est pas celle d'un média WordPress.
String? cheminMedia(String url) {
  final int debut = url.indexOf(_repereMedias);
  if (debut == -1) return null;
  return url.substring(debut + _repereMedias.length);
}

/// URL complète d'un média de production à partir de son chemin relatif.
String urlMedia(String chemin) => '$dossierMedias$chemin';

/// Une photo et ses trois tailles, fournies par le champ `spi_images` de
/// l'API (mu-plugin spi-images-rest.php du site).
class ImageWpInfo {
  /// Identifiant du média WordPress (« 64519 ») : clé des favoris dans
  /// Firestore, identique sur le site local et en production. null si la
  /// photo n'en a pas : elle ne peut alors pas être mise en favori.
  final String? mediaId;
  final String thumbnailUrl; // vignette carrée 320 px — grilles
  final String ecranUrl; // taille « large » (1920 px max) — affichage
  final String landscapeUrl; // original — fond d'écran, partage
  final String description;

  /// Titre de l'album d'origine, quand il est connu au niveau de la photo
  /// (fil du Club : chaque photo vient d'un album différent).
  final String? album;

  ImageWpInfo({
    required this.mediaId,
    required this.thumbnailUrl,
    required this.ecranUrl,
    required this.landscapeUrl,
    required this.description,
    this.album,
  });

  /// Une entrée de `spi_images`. Une taille absente retombe sur l'original.
  factory ImageWpInfo.fromJson(Map<String, dynamic> json,
      {String description = ''}) {
    final String original = json['original'] as String? ?? '';
    final Object? id = json['id'];
    return ImageWpInfo(
      mediaId: id is int ? '$id' : null,
      thumbnailUrl: json['vignette'] as String? ?? original,
      ecranUrl: json['ecran'] as String? ?? original,
      landscapeUrl: original,
      description: description,
    );
  }

  /// Photo favorite, à partir de l'identifiant et des chemins relatifs
  /// enregistrés dans Firestore. Une taille absente retombe sur l'original.
  factory ImageWpInfo.favori({
    required String mediaId,
    required String photoPath,
    String? vignettePath,
    String? ecranPath,
    String? album,
  }) {
    final String original = urlMedia(photoPath);
    return ImageWpInfo(
      mediaId: mediaId,
      thumbnailUrl: vignettePath != null ? urlMedia(vignettePath) : original,
      ecranUrl: ecranPath != null ? urlMedia(ecranPath) : original,
      landscapeUrl: original,
      description: album ?? 'Photo favorite',
      album: album,
    );
  }
}
