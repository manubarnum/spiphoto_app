import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiphoto_app/service/sources/modeles.dart';
import 'package:spiphoto_app/service/sources/source_lychee.dart';
import 'package:spiphoto_app/service/sources/source_photos.dart';
import 'package:spiphoto_app/service/sources/source_piwigo.dart';
import 'package:spiphoto_app/service/sources/source_spiphoto.dart';

/// Sources de photos de l'utilisateur : spiphoto.fr (toujours en tête, non
/// supprimable), puis les galeries d'adhérents qu'il a activées, puis les
/// autres sites ajoutés. Les choix sont gardés entre deux lancements.
///
/// La liste des galeries d'adhérents vient de spiphoto.fr
/// (`sps/v1/galeries`, mêmes sites que la pellicule du site) ; la dernière
/// reçue est gardée pour le hors-ligne. Seules les galeries que l'appli sait
/// lire (Piwigo, Lychee) y figurent.
class SourcesService {
  SourcesService._internal();
  static final SourcesService instance = SourcesService._internal();

  static const String cleSources = 'spiphoto-sources';
  static const String cleSourceActive = 'spiphoto-source-active';
  static const String cleGaleries = 'spiphoto-galeries-adherents';

  static final Uri adresseGaleries =
      Uri.parse('https://www.spiphoto.fr/wp-json/sps/v1/galeries');

  static SourceConfig get spiphoto => SourceSpiphoto.configuration;

  final ValueNotifier<List<SourceConfig>> _sources =
      ValueNotifier<List<SourceConfig>>([SourceSpiphoto.configuration]);
  final ValueNotifier<List<SourceConfig>> _galeries =
      ValueNotifier<List<SourceConfig>>(const []);
  final ValueNotifier<SourceConfig> _active =
      ValueNotifier<SourceConfig>(SourceSpiphoto.configuration);

  // Faux tant qu'aucune liste n'a été reçue (premier lancement hors
  // ligne) : les galeries activées sont alors gardées telles quelles.
  bool _listeConnue = false;

  // Une instance par source : la liste d'albums et la session Lychee
  // survivent à un changement de source.
  final Map<SourceConfig, SourcePhotos> _instances = {};

  /// Sources proposées dans le sélecteur, dans l'ordre d'affichage.
  ValueListenable<List<SourceConfig>> get sources => _sources;

  /// Galeries d'adhérents proposées à l'activation (Piwigo et Lychee).
  ValueListenable<List<SourceConfig>> get galeriesAdherents => _galeries;

  /// Source affichée dans l'onglet Albums.
  ValueListenable<SourceConfig> get sourceActive => _active;

  /// Lit les choix enregistrés et la dernière liste des galeries reçue,
  /// sans réseau. [actualiserGaleries] met ensuite la liste à jour.
  Future<void> init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _instances.clear();
    final String? copie = prefs.getString(cleGaleries);
    _listeConnue = copie != null;
    _galeries.value = copie != null ? galeriesDepuisJson(copie) : const [];
    _sources.value = ordonner(
      _lireListe(prefs.getString(cleSources)),
      _listeConnue ? _galeries.value : null,
    );
    final String? active = prefs.getString(cleSourceActive);
    _active.value = sourceValide(
      active == null ? null : SourceConfig.depuisJson(_decoder(active)),
      _sources.value,
    );
  }

  /// Télécharge la liste des galeries d'adhérents et l'enregistre. Une
  /// galerie sortie de la liste (lien rendu privé, galerie illisible)
  /// disparaît des sources de l'utilisateur. Lève une exception en cas
  /// d'échec : la dernière liste reçue reste alors en place.
  Future<void> actualiserGaleries(
      {@visibleForTesting Future<String> Function()? telecharger}) async {
    final String corps = await (telecharger ?? _telechargerGaleries)();
    final List<SourceConfig> galeries = galeriesDepuisJson(corps);
    // Réponse illisible (page d'erreur, maintenance) : rien n'est changé.
    if (galeries.isEmpty && jsonDecodeOuNull(corps) is! List) {
      throw const FormatException('Liste des galeries illisible');
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(cleGaleries, corps);
    _listeConnue = true;
    _galeries.value = galeries;
    await _appliquer(ordonner(_sources.value, galeries));
  }

  /// Ajoute une galerie d'adhérents aux sources (sans la rendre active).
  Future<void> activerGalerie(SourceConfig galerie) async {
    if (!_galeries.value.contains(galerie)) return;
    await _appliquer(ordonner(
        [..._sources.value, galerie], _listeConnue ? _galeries.value : null));
  }

  /// Retire une galerie d'adhérents, ou un autre site, des sources.
  /// spiphoto.fr ne peut pas être retiré.
  Future<void> retirer(SourceConfig source) async {
    if (source == spiphoto) return;
    _instances.remove(source);
    await _appliquer(_sources.value.where((s) => s != source).toList());
  }

  /// Désactiver une galerie d'adhérents = la retirer des sources.
  Future<void> desactiverGalerie(SourceConfig galerie) => retirer(galerie);

  /// Affiche [source] dans l'onglet Albums (elle doit être dans les
  /// sources).
  Future<void> activer(SourceConfig source) async {
    if (!_sources.value.contains(source)) return;
    _active.value = source;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(cleSourceActive, jsonEncode(source.toJson()));
  }

  /// La source qui lit [config], créée une seule fois.
  SourcePhotos sourcePour(SourceConfig config) =>
      _instances.putIfAbsent(config, () => creerSource(config));

  Future<void> _appliquer(List<SourceConfig> sources) async {
    _sources.value = sources;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        cleSources,
        jsonEncode(sources
            .where((s) => s != spiphoto)
            .map((s) => s.toJson())
            .toList()));
    final SourceConfig active = sourceValide(_active.value, sources);
    if (active != _active.value) await activer(active);
  }

  static Future<String> _telechargerGaleries() async {
    final response = await http.get(adresseGaleries, headers: {
      'User-Agent': userAgentSources,
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception(
          'Impossible de charger les galeries (${response.statusCode})');
    }
    return utf8.decode(response.bodyBytes);
  }

  static List<SourceConfig> _lireListe(String? json) {
    final Object? liste = json == null ? null : _decoder(json);
    return liste is List
        ? liste.map(SourceConfig.depuisJson).whereType<SourceConfig>().toList()
        : const [];
  }

  static Object? _decoder(String json) => jsonDecodeOuNull(json);

  // ───────────────────────────────────────────────────────────────────────
  // FONCTIONS PURES (testées)
  // ───────────────────────────────────────────────────────────────────────

  /// Source capable de lire [config].
  static SourcePhotos creerSource(SourceConfig config) => switch (config.type) {
        TypeSource.spiphoto => const SourceSpiphoto(),
        TypeSource.piwigo => SourcePiwigo(config),
        TypeSource.lychee => SourceLychee(config),
        TypeSource.wordpress =>
          throw UnsupportedError('Sites WordPress : pas encore pris en charge'),
      };

  /// Galeries de `sps/v1/galeries` que l'appli sait lire (Piwigo, Lychee) ;
  /// les entrées `autre`, incomplètes ou de type inconnu sont ignorées.
  static List<SourceConfig> galeriesDepuisJson(String corps) {
    final Object? json = jsonDecodeOuNull(corps);
    if (json is! List) return const [];
    final List<SourceConfig> galeries = [];
    for (final Object? entree in json) {
      if (entree is! Map) continue;
      final TypeSource? type = switch (entree['type']) {
        'piwigo' => TypeSource.piwigo,
        'lychee' => TypeSource.lychee,
        _ => null,
      };
      final Object? adresse = entree['adresse'];
      final Object? nom = entree['nom'];
      final Uri? uri = adresse is String ? Uri.tryParse(adresse) : null;
      if (type == null ||
          nom is! String ||
          nom.trim().isEmpty ||
          uri == null ||
          !(uri.isScheme('http') || uri.isScheme('https')) ||
          uri.host.isEmpty) {
        continue;
      }
      final Object? image = entree['image'];
      final SourceConfig galerie = SourceConfig(
        type: type,
        adresse: racineSource(uri),
        nom: nom.trim(),
        image: image is String && image.isNotEmpty ? image : null,
        adherent: true,
      );
      if (!galeries.contains(galerie)) galeries.add(galerie);
    }
    return galeries;
  }

  /// Sources dans l'ordre d'affichage : spiphoto.fr, puis les galeries
  /// d'adhérents activées (dans l'ordre de la liste, avec leur nom et leur
  /// vignette à jour), puis les autres sites, sans doublon. Avec [galeries]
  /// à null (liste jamais reçue), les galeries activées sont gardées telles
  /// quelles ; sinon celles qui ne sont plus dans la liste sont retirées.
  static List<SourceConfig> ordonner(
      List<SourceConfig> enregistrees, List<SourceConfig>? galeries) {
    final List<SourceConfig> adherents = enregistrees
        .where((s) => s.adherent && s.type != TypeSource.spiphoto)
        .toList();
    final List<SourceConfig> autres = enregistrees
        .where((s) => !s.adherent && s.type != TypeSource.spiphoto)
        .toList();
    return <SourceConfig>{
      SourceSpiphoto.configuration,
      if (galeries == null)
        ...adherents
      else
        ...galeries.where(adherents.contains),
      ...autres,
    }.toList();
  }

  /// [active] si elle fait partie des [sources], sinon spiphoto.fr.
  static SourceConfig sourceValide(
          SourceConfig? active, List<SourceConfig> sources) =>
      active != null && sources.contains(active)
          ? sources.firstWhere((s) => s == active)
          : SourceSpiphoto.configuration;
}

/// JSON décodé, ou null s'il est invalide.
Object? jsonDecodeOuNull(String texte) {
  try {
    return jsonDecode(texte);
  } on FormatException {
    return null;
  }
}
