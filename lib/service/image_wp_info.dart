// image_wp_info.dart

/// Suffixe de taille ajouté par WordPress aux fichiers image (ex. "-150x150",
/// "-300x300"). Ce réglage ("Taille des vignettes") a changé au fil du temps
/// sur le site — on le détecte donc par motif plutôt que par valeur fixe.
final RegExp wpImageSizeSuffix = RegExp(r'-\d+x\d+(?=\.[a-zA-Z]+$)');

/// Retire le suffixe de taille WordPress d'une URL pour retrouver le nom de
/// fichier de l'image originale (plein format).
String stripWpImageSize(String url) => url.replaceFirst(wpImageSizeSuffix, '');

/// Insère un suffixe de taille avant l'extension d'une URL déjà dépourvue
/// de suffixe (voir [stripWpImageSize]).
String insertWpImageSize(String baseUrl, String suffix) {
  final int lastDot = baseUrl.lastIndexOf('.');
  if (lastDot == -1) return baseUrl;
  return '${baseUrl.substring(0, lastDot)}$suffix${baseUrl.substring(lastDot)}';
}

class ImageWpInfo {
  final String portraitUrl; // src original WordPress (taille variable)
  final String thumbnailUrl; // 320x320 — vignette (reconstruite)
  final String fallbackUrl; // repli si la vignette 320x320 est absente
  final String landscapeUrl; // full — plein écran
  final String description;
  final bool isFavorite;

  /// Titre de l'album d'origine, quand il est connu au niveau de la photo
  /// (fil du Club : chaque photo vient d'un album différent).
  final String? album;

  ImageWpInfo({
    required this.portraitUrl,
    required this.thumbnailUrl,
    required this.fallbackUrl,
    required this.landscapeUrl,
    required this.description,
    this.isFavorite = false,
    this.album,
  });

  /// Reconstruit un ImageWpInfo à partir de la seule URL plein format
  /// (landscapeUrl), telle que stockée dans Firestore pour les favoris.
  ///
  /// On retire d'abord un éventuel suffixe de taille déjà présent (défense
  /// contre d'anciennes entrées Firestore enregistrées avant ce correctif,
  /// où landscapeUrl gardait par erreur son suffixe d'origine) avant
  /// d'insérer les suffixes de taille voulus.
  /// Exemple :
  ///   .../photo.jpg  →  .../photo-150x150.jpg  (portraitUrl)
  ///                  →  .../photo-320x320.jpg  (thumbnailUrl / fallbackUrl)
  factory ImageWpInfo.fromFavoriteUrl(String landscapeUrl, {String? album}) {
    final String baseUrl = stripWpImageSize(landscapeUrl);

    return ImageWpInfo(
      portraitUrl: insertWpImageSize(baseUrl, '-150x150'),
      thumbnailUrl: insertWpImageSize(baseUrl, '-320x320'),
      fallbackUrl: baseUrl,
      landscapeUrl: baseUrl,
      description: 'Photo favorite',
      isFavorite: true,
      album: album,
    );
  }
}
