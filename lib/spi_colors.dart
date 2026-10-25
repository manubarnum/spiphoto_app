import 'package:flutter/material.dart';

/// Palette de couleurs SPIPHOTO
///
/// Cette classe centralise tous les codes couleur de l'application.
/// Elle est utilisée pour garantir une cohérence visuelle sur l'ensemble
/// de l'interface et de l'expérience utilisateur.
class SpiColors {
  SpiColors._();

  /// Couleurs principales
  static const Color olive = Color(0xFF4B5A22); // vert olive — primaire
  static const Color mauve = Color(0xFF936893); // mauve prune — secondaire

  /// Déclinaisons primaire (hover / pressed)
  static const Color oliveFonce = Color(0xFF3A4519);
  static const Color oliveClair = Color(0xFF5E7029);

  /// Déclinaisons secondaire (hover / pressed)
  static const Color mauveFonce = Color(0xFF7A5579);
  static const Color mauveClair = Color(0xFFAD80AD);

  /// Fonds
  static const Color noir = Color(0xFF0D0E09); // fond principal
  static const Color surface = Color(0xFF161A0E); // cartes / surfaces
  static const Color surfaceAlt = Color(0xFF1E2412); // surfaces secondaires
  static const Color surfaceHigh = Color(0xFF252C16); // surfaces élevées

  /// Textes
  static const Color texte = Color(0xFFF2EFE8); // blanc crème — principal
  static const Color texteMuted = Color(0xFF9E9A8E); // gris chaud — secondaire
  static const Color texteTertiaire = Color(0xFF7C7870); // métadonnées
  static const Color texteDisable = Color(0xFF5A5750); // désactivé

  /// Utilitaires
  static const Color overlay = Color(0xCC0D0E09); // overlay images
  static const Color overlayLight = Color(0x800D0E09); // overlay léger
  static const Color erreur = Color(0xFFCF6679); // erreurs
  static const Color succes = Color(0xFF6A8F3A); // succès
}

/// Couleurs qui changent avec le thème clair / sombre, lues via
/// `context.spi`. Les couleurs de [SpiColors] restent valables pour ce qui
/// ne dépend pas du thème : olive (action primaire, texte crème dessus),
/// textes posés sur une photo, visionneuse et aperçu (toujours sombres).
@immutable
class SpiPalette extends ThemeExtension<SpiPalette> {
  final Color fond; // fond d'écran (scaffold)
  final Color surface; // barres d'app, nav basse, cartes, panneaux
  final Color surfaceAlt; // emplacements photo en chargement
  final Color surfaceElevee; // avatar, piste de réglette, séparateurs
  final Color encre; // texte principal
  final Color encreSecondaire; // texte secondaire, icônes inactives
  final Color encreTertiaire; // métadonnées, points inactifs
  final Color accent; // compteurs, favori actif, profil
  final Color mauve; // onglet actif, indicateurs, liens d'action

  const SpiPalette({
    required this.fond,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceElevee,
    required this.encre,
    required this.encreSecondaire,
    required this.encreTertiaire,
    required this.accent,
    required this.mauve,
  });

  static const SpiPalette sombre = SpiPalette(
    fond: SpiColors.noir,
    surface: SpiColors.surface,
    surfaceAlt: SpiColors.surfaceAlt,
    surfaceElevee: SpiColors.surfaceHigh,
    encre: SpiColors.texte,
    encreSecondaire: SpiColors.texteMuted,
    encreTertiaire: SpiColors.texteTertiaire,
    accent: SpiColors.mauveClair,
    mauve: SpiColors.mauve,
  );

  // Valeurs du mode clair du site (thème FSE spiphoto_web, style.css,
  // html[data-theme="light"]) pour un jour/nuit homogène entre le site et
  // l'app. Correspondances : bg, surface, surface-raised, surface-top, text,
  // text-secondary, text-muted ; le mauve passe à secondary-dark, comme
  // l'accent du site en clair.
  static const SpiPalette clair = SpiPalette(
    fond: Color(0xFFF7F3EC),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEEE9DF),
    surfaceElevee: Color(0xFFE5DFD3),
    encre: Color(0xFF1C1E0F),
    encreSecondaire: Color(0xFF3E4028),
    encreTertiaire: Color(0xFF7A7660),
    accent: Color(0xFF7A5579),
    mauve: Color(0xFF7A5579),
  );

  @override
  SpiPalette copyWith({
    Color? fond,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceElevee,
    Color? encre,
    Color? encreSecondaire,
    Color? encreTertiaire,
    Color? accent,
    Color? mauve,
  }) {
    return SpiPalette(
      fond: fond ?? this.fond,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      surfaceElevee: surfaceElevee ?? this.surfaceElevee,
      encre: encre ?? this.encre,
      encreSecondaire: encreSecondaire ?? this.encreSecondaire,
      encreTertiaire: encreTertiaire ?? this.encreTertiaire,
      accent: accent ?? this.accent,
      mauve: mauve ?? this.mauve,
    );
  }

  @override
  SpiPalette lerp(SpiPalette? other, double t) {
    if (other == null) return this;
    return SpiPalette(
      fond: Color.lerp(fond, other.fond, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      surfaceElevee: Color.lerp(surfaceElevee, other.surfaceElevee, t)!,
      encre: Color.lerp(encre, other.encre, t)!,
      encreSecondaire: Color.lerp(encreSecondaire, other.encreSecondaire, t)!,
      encreTertiaire: Color.lerp(encreTertiaire, other.encreTertiaire, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      mauve: Color.lerp(mauve, other.mauve, t)!,
    );
  }
}

extension SpiPaletteContext on BuildContext {
  /// Palette du thème courant (clair ou sombre).
  SpiPalette get spi => Theme.of(this).extension<SpiPalette>()!;
}
