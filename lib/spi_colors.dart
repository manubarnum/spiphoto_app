import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PALETTE SPIPHOTO
// ─────────────────────────────────────────────────────────────────────────────
class SpiColors {
  SpiColors._();

  // Couleurs principales
  static const Color olive = Color(0xFF4B5A22); // vert olive — primaire
  static const Color mauve = Color(0xFF936893); // mauve prune — secondaire

  // Déclinaisons primaire
  static const Color oliveFonce = Color(0xFF3A4519); // hover / pressed olive
  static const Color oliveClair = Color(0xFF5E7029); // variante claire

  // Déclinaisons secondaire
  static const Color mauveFonce = Color(0xFF7A5579); // hover / pressed mauve
  static const Color mauveClair = Color(0xFFAD80AD); // variante claire

  // Fonds
  static const Color noir = Color(0xFF0D0E09); // fond principal
  static const Color surface = Color(0xFF161A0E); // cartes / surfaces
  static const Color surfaceAlt = Color(0xFF1E2412); // surfaces secondaires
  static const Color surfaceHigh = Color(0xFF252C16); // surfaces élevées

  // Textes
  static const Color texte = Color(0xFFF2EFE8); // blanc crème — principal
  static const Color texteMuted = Color(0xFF9E9A8E); // gris chaud — secondaire
  static const Color texteDisable = Color(0xFF5A5750); // désactivé

  // Utilitaires
  static const Color overlay = Color(0xCC0D0E09); // overlay images
  static const Color overlayLight = Color(0x800D0E09); // overlay léger
  static const Color erreur = Color(0xFFCF6679); // erreurs
  static const Color succes = Color(0xFF6A8F3A); // succès
}
