// image_wp_info.dart

/// Extension d'un fichier image WordPress. Les copies WebP générées par
/// Perfect Images gardent l'extension d'origine : « photo-150x150.jpeg.webp ».
const String _wpImageExtension = r'\.[a-zA-Z]+(?:\.webp)?$';
final RegExp _wpImageExtensionPattern = RegExp(_wpImageExtension);

/// Suffixe de taille ajouté par WordPress aux fichiers image (ex. "-150x150",
/// "-300x300"). Ce réglage ("Taille des vignettes") a changé au fil du temps
/// sur le site — on le détecte donc par motif plutôt que par valeur fixe.
final RegExp wpImageSizeSuffix = RegExp('-\\d+x\\d+(?=$_wpImageExtension)');

/// Retire le suffixe de taille WordPress d'une URL pour retrouver le nom de
/// fichier de l'image originale (plein format).
String stripWpImageSize(String url) => url.replaceFirst(wpImageSizeSuffix, '');

/// Insère un suffixe de taille avant l'extension d'une URL déjà dépourvue
/// de suffixe (voir [stripWpImageSize]), double extension WebP comprise :
/// « photo.jpeg.webp » donne « photo-320x320.jpeg.webp ».
String insertWpImageSize(String baseUrl, String suffix) {
  final Match? extension = _wpImageExtensionPattern.firstMatch(baseUrl);
  if (extension == null) return baseUrl;
  final int debut = extension.start;
  return '${baseUrl.substring(0, debut)}$suffix${baseUrl.substring(debut)}';
}

/// Identifiant de repli d'une photo sans identifiant WordPress : son URL
/// d'original encodée, comme pour les favoris des versions précédentes.
String mediaIdDepuisUrl(String url) =>
    Uri.encodeComponent(stripWpImageSize(url));

/// Une photo et ses trois tailles, fournies par le champ `spi_images` de
/// l'API (mu-plugin spi-images-rest.php du site).
class ImageWpInfo {
  /// Identifiant du média WordPress : clé des favoris dans Firestore, stable
  /// quel que soit le format servi (WebP ou non, -scaled…).
  final String mediaId;
  final String thumbnailUrl; // vignette carrée 320 px — grilles
  final String ecranUrl; // taille « large » (1920 px max) — affichage
  final String landscapeUrl; // original — fond d'écran, partage, favoris
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
      mediaId: id is int ? '$id' : mediaIdDepuisUrl(original),
      thumbnailUrl: json['vignette'] as String? ?? original,
      ecranUrl: json['ecran'] as String? ?? original,
      landscapeUrl: original,
      description: description,
    );
  }

  /// Photo favorite, à partir de l'identifiant et des URL enregistrés dans
  /// Firestore.
  ///
  /// Les favoris enregistrés par les versions précédentes de l'app n'ont que
  /// l'URL de l'original : la vignette est alors reconstruite à partir du
  /// nom de fichier, et l'original sert à l'affichage.
  factory ImageWpInfo.fromFavoriteUrl(String landscapeUrl,
      {String? mediaId,
      String? thumbnailUrl,
      String? ecranUrl,
      String? album}) {
    final String baseUrl = stripWpImageSize(landscapeUrl);

    return ImageWpInfo(
      mediaId: mediaId ?? mediaIdDepuisUrl(baseUrl),
      thumbnailUrl: thumbnailUrl ?? insertWpImageSize(baseUrl, '-320x320'),
      ecranUrl: ecranUrl ?? baseUrl,
      landscapeUrl: baseUrl,
      description: album ?? 'Photo favorite',
      album: album,
    );
  }
}
