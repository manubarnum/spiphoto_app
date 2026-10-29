import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Choix du mode jour / nuit, persistant entre deux lancements
/// (shared_preferences). Même logique que le site (spiphoto_web) : tant que
/// l'utilisateur n'a rien choisi, on suit le réglage de l'appareil.
class ThemeService {
  // ── Singleton, même logique que pour AuthService ──────────────────────
  ThemeService._internal();
  static final ThemeService instance = ThemeService._internal();

  static const String _cle = 'spiphoto-theme'; // même clé que le site
  static const String _jour = 'light';
  static const String _nuit = 'dark';

  /// true = nuit, false = jour, null = réglage de l'appareil. Écouté par
  /// MaterialApp et par les boutons de bascule.
  final ValueNotifier<bool?> sombre = ValueNotifier<bool?>(null);

  /// Lit le choix enregistré. À appeler avant runApp() pour démarrer
  /// directement dans le bon thème, sans flash de l'autre.
  Future<void> init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    sombre.value = switch (prefs.getString(_cle)) {
      _jour => false,
      _nuit => true,
      _ => null,
    };
  }

  /// Bascule jour ⇄ nuit à partir du thème affiché ([sombreAffiche], qui
  /// tient compte du réglage de l'appareil) et enregistre le choix.
  Future<void> basculer({required bool sombreAffiche}) async {
    sombre.value = !sombreAffiche;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cle, sombre.value! ? _nuit : _jour);
  }
}
