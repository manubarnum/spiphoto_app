// image_wp_info.dart
class ImageWpInfo {
  final String portraitUrl; // 150x150  — src original WordPress
  final String thumbnailUrl; // 600x600  — vignette optimisée (reconstruite)
  final String fallbackUrl; // 320x320  — garanti présent si 600x600 absent
  final String landscapeUrl; // full     — plein écran
  final String description;

  ImageWpInfo({
    required this.portraitUrl,
    required this.thumbnailUrl,
    required this.fallbackUrl,
    required this.landscapeUrl,
    required this.description,
  });
}
