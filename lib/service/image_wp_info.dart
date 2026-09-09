// image_wp_info.dart
class ImageWpInfo {
  final String portraitUrl; // 150x150  — src original WordPress
  final String thumbnailUrl; // 600x600  — vignette optimisée (reconstruite)
  final String fallbackUrl; // 320x320  — garanti présent si 600x600 absent
  final String landscapeUrl; // full     — plein écran
  final String description;
  final bool isFavorite;

  ImageWpInfo({
    required this.portraitUrl,
    required this.thumbnailUrl,
    required this.fallbackUrl,
    required this.landscapeUrl,
    required this.description,
    this.isFavorite = false,
  });

  /// Reconstruit un ImageWpInfo à partir de la seule URL plein format
  /// (landscapeUrl), telle que stockée dans Firestore pour les favoris.
  ///
  /// Contrairement à extractImagesFromHtml() (qui part d'un src 150x150 et
  /// RETIRE le suffixe pour obtenir le plein format), ici on part du plein
  /// format et on INSÈRE le suffixe de taille avant l'extension du fichier.
  /// Exemple :
  ///   .../photo.jpg  →  .../photo-600x600.jpg  (thumbnailUrl)
  ///                  →  .../photo-320x320.jpg  (fallbackUrl)
  factory ImageWpInfo.fromFavoriteUrl(String landscapeUrl) {
    final int lastDot = landscapeUrl.lastIndexOf('.');
    String withSize(String suffix) {
      if (lastDot == -1) return landscapeUrl; // pas d'extension trouvée
      return '${landscapeUrl.substring(0, lastDot)}$suffix${landscapeUrl.substring(lastDot)}';
    }

    return ImageWpInfo(
      portraitUrl: withSize('-150x150'),
      thumbnailUrl: withSize('-600x600'),
      fallbackUrl: withSize('-320x320'),
      landscapeUrl: landscapeUrl,
      description: 'Photo favorite',
      isFavorite: true,
    );
  }
}
