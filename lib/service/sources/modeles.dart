import 'package:spiphoto_app/service/image_wp_info.dart';

/// Logiciel d'une source de photos.
enum TypeSource { spiphoto, wordpress, piwigo, lychee }

/// Source de photos enregistrée par l'utilisateur (persistée en JSON).
class SourceConfig {
  final TypeSource type;

  /// Racine du site, ex. https://galerie.exemple.fr/
  final Uri adresse;

  /// Nom affiché, ex. « Galerie de Jean D. ».
  final String nom;

  /// Vignette fournie par la liste des galeries d'adhérents, ou null.
  final String? image;

  /// Vrai si la source vient de la liste des galeries d'adhérents.
  final bool adherent;

  const SourceConfig({
    required this.type,
    required this.adresse,
    required this.nom,
    this.image,
    this.adherent = false,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'adresse': adresse.toString(),
        'nom': nom,
        if (image != null) 'image': image,
        if (adherent) 'adherent': true,
      };

  /// Source relue depuis [toJson], ou null si l'entrée est incomplète ou
  /// d'un type inconnu (enregistrée par une autre version de l'appli).
  static SourceConfig? depuisJson(Object? json) {
    if (json is! Map) return null;
    final TypeSource? type = TypeSource.values.asNameMap()[json['type']];
    final Object? adresse = json['adresse'];
    final Object? nom = json['nom'];
    if (type == null || adresse is! String || nom is! String) return null;
    final Uri? uri = Uri.tryParse(adresse);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    final Object? image = json['image'];
    return SourceConfig(
      type: type,
      adresse: uri,
      nom: nom,
      image: image is String ? image : null,
      adherent: json['adherent'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SourceConfig && other.type == type && other.adresse == adresse;

  @override
  int get hashCode => Object.hash(type, adresse);
}

/// Catégorie proposée en filtre des albums.
class Categorie {
  final String id;
  final String nom;
  final int? nbAlbums;

  const Categorie({required this.id, required this.nom, this.nbAlbums});
}

/// Un album d'une source.
class Album {
  /// Identifiant propre à la source (texte : Lychee n'a pas d'entiers).
  final String id;
  String title;

  /// Nom affiché de l'auteur, ou null s'il n'est pas connu.
  final String? authorName;

  /// Photos de l'album, dans l'ordre. Vide tant que l'album n'est pas
  /// ouvert pour les sources qui ne les donnent pas avec la liste.
  final List<ImageWpInfo> images;

  /// Photo de couverture fournie par la source, à défaut la 1re photo.
  final ImageWpInfo? couverture;

  /// Nombre de photos annoncé par la source (null s'il est inconnu).
  final int? nbPhotosAnnonce;

  Album({
    required this.id,
    required this.title,
    required this.images,
    this.authorName,
    this.couverture,
    this.nbPhotosAnnonce,
  }) {
    title = title.replaceAll('&rsquo;', '’');
  }

  ImageWpInfo? get photoCouverture =>
      couverture ?? (images.isNotEmpty ? images.first : null);

  /// Nombre de photos, ou null s'il n'est pas connu avant l'ouverture.
  int? get nbPhotos => images.isNotEmpty ? images.length : nbPhotosAnnonce;
}

/// Une page d'albums et les totaux de la source.
class PageAlbums {
  final List<Album> albums;
  final int total;
  final int totalPages;

  const PageAlbums({
    required this.albums,
    required this.total,
    required this.totalPages,
  });
}
