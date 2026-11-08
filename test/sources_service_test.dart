import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiphoto_app/service/sources/modeles.dart';
import 'package:spiphoto_app/service/sources/source_lychee.dart';
import 'package:spiphoto_app/service/sources/source_piwigo.dart';
import 'package:spiphoto_app/service/sources/source_spiphoto.dart';
import 'package:spiphoto_app/service/sources/sources_service.dart';

/// Réponse réelle de spiphoto.fr/wp-json/sps/v1/galeries (8 nov. 2026).
final String galeriesReelles =
    File('test/fixtures/galeries.json').readAsStringSync();

SourceConfig galerie(String nom, TypeSource type, String adresse) =>
    SourceConfig(
        type: type, adresse: Uri.parse(adresse), nom: nom, adherent: true);

void main() {
  final SourceConfig spiphoto = SourceSpiphoto.configuration;

  group('galeriesDepuisJson', () {
    final List<SourceConfig> galeries =
        SourcesService.galeriesDepuisJson(galeriesReelles);

    test('les 8 galeries lisibles, galeries « autre » masquées', () {
      expect(galeries, hasLength(8));
      expect(galeries.map((g) => g.nom), isNot(contains('Sellig')));
      expect(galeries.map((g) => g.nom), isNot(contains('Mathieu')));
      expect(
          galeries.where((g) => g.type == TypeSource.lychee).map((g) => g.nom),
          ['Colin', 'Nathalie']);
      expect(galeries.every((g) => g.adherent), isTrue);
    });

    test('adresses en https, terminées par « / » ; vignette du site', () {
      final SourceConfig frederic =
          galeries.firstWhere((g) => g.nom == 'Frederic');
      expect(frederic.adresse, Uri.parse('https://fred.declic.spiphoto.fr/'));
      expect(frederic.image,
          startsWith('https://www.spiphoto.fr/wordpress/wp-content/uploads/'));
      expect(galeries.firstWhere((g) => g.nom == 'Fabienne').adresse,
          Uri.parse('https://fabienne.spiphoto.fr/'));
    });

    test('entrées incomplètes, type inconnu, adresse invalide, doublon', () {
      final List<SourceConfig> lues =
          SourcesService.galeriesDepuisJson(jsonEncode([
        {'nom': 'A', 'type': 'piwigo', 'adresse': 'https://a.spiphoto.fr/'},
        {'nom': 'A bis', 'type': 'piwigo', 'adresse': 'http://a.spiphoto.fr'},
        {'nom': 'B', 'type': 'coppermine', 'adresse': 'https://b.fr/'},
        {'nom': 'C', 'type': 'lychee'},
        {'nom': '', 'type': 'lychee', 'adresse': 'https://c.fr/'},
        {'nom': 'D', 'type': 'lychee', 'adresse': 'ftp://d.fr/'},
        'texte',
      ]));
      expect(lues.map((g) => g.nom), ['A']);
      expect(lues.single.image, isNull);
      expect(SourcesService.galeriesDepuisJson('<html>erreur</html>'), isEmpty);
      expect(SourcesService.galeriesDepuisJson('{}'), isEmpty);
    });
  });

  group('ordonner', () {
    final SourceConfig alain =
        galerie('Alain', TypeSource.piwigo, 'https://alain.spiphoto.fr/');
    final SourceConfig colin =
        galerie('Colin', TypeSource.lychee, 'https://progpix.spiphoto.fr/');
    final SourceConfig blog = SourceConfig(
        type: TypeSource.wordpress,
        adresse: Uri.parse('https://blog.exemple.fr/'),
        nom: 'Blog');

    test(
        'spiphoto.fr en tête, galeries dans l\'ordre de la liste, autres sites',
        () {
      expect(SourcesService.ordonner([blog, colin, alain], [alain, colin]),
          [spiphoto, alain, colin, blog]);
    });

    test('galerie sortie de la liste : retirée', () {
      expect(
          SourcesService.ordonner([alain, colin], [colin]), [spiphoto, colin]);
    });

    test('liste jamais reçue : galeries activées gardées', () {
      expect(SourcesService.ordonner([colin, alain], null),
          [spiphoto, colin, alain]);
    });

    test('nom et vignette repris de la liste', () {
      final SourceConfig renommee = SourceConfig(
          type: TypeSource.piwigo,
          adresse: alain.adresse,
          nom: 'Alain D.',
          image: 'https://www.spiphoto.fr/v.webp',
          adherent: true);
      final List<SourceConfig> sources =
          SourcesService.ordonner([alain], [renommee]);
      expect(sources.last.nom, 'Alain D.');
      expect(sources.last.image, 'https://www.spiphoto.fr/v.webp');
    });

    test('doublons et spiphoto.fr enregistré : une seule fois', () {
      expect(SourcesService.ordonner([spiphoto, blog, blog], const []),
          [spiphoto, blog]);
    });

    test('source active disparue : retour à spiphoto.fr', () {
      expect(SourcesService.sourceValide(colin, [spiphoto, alain]), spiphoto);
      expect(SourcesService.sourceValide(alain, [spiphoto, alain]), alain);
      expect(SourcesService.sourceValide(null, [spiphoto]), spiphoto);
    });
  });

  test('creerSource : une source par type', () {
    expect(SourcesService.creerSource(spiphoto), isA<SourceSpiphoto>());
    expect(
        SourcesService.creerSource(
            galerie('A', TypeSource.piwigo, 'https://a.spiphoto.fr/')),
        isA<SourcePiwigo>());
    expect(
        SourcesService.creerSource(
            galerie('C', TypeSource.lychee, 'https://c.spiphoto.fr/')),
        isA<SourceLychee>());
  });

  group('SourcesService', () {
    final SourcesService service = SourcesService.instance;
    Future<String> reelles() async => galeriesReelles;

    test('premier lancement hors ligne : spiphoto.fr seul', () async {
      SharedPreferences.setMockInitialValues({});
      await service.init();
      expect(service.sources.value, [spiphoto]);
      expect(service.galeriesAdherents.value, isEmpty);
      expect(service.sourceActive.value, spiphoto);
    });

    test('activer une galerie, l\'afficher, retrouver le tout au relancement',
        () async {
      SharedPreferences.setMockInitialValues({});
      await service.init();
      await service.actualiserGaleries(telecharger: reelles);
      final SourceConfig nathalie = service.galeriesAdherents.value
          .firstWhere((g) => g.nom == 'Nathalie');

      await service.activerGalerie(nathalie);
      await service.activer(nathalie);
      expect(service.sources.value, [spiphoto, nathalie]);
      expect(service.sourceActive.value, nathalie);

      // Relancement hors ligne : choix et liste relus des préférences.
      await service.init();
      expect(service.sources.value, [spiphoto, nathalie]);
      expect(service.sourceActive.value, nathalie);
      expect(service.galeriesAdherents.value, hasLength(8));
      expect(service.sourcePour(nathalie), isA<SourceLychee>());
      expect(
          identical(service.sourcePour(nathalie), service.sourcePour(nathalie)),
          isTrue);
    });

    test('galerie rendue privée sur le site : retirée, retour à spiphoto.fr',
        () async {
      SharedPreferences.setMockInitialValues({});
      await service.init();
      await service.actualiserGaleries(telecharger: reelles);
      final SourceConfig alain =
          service.galeriesAdherents.value.firstWhere((g) => g.nom == 'Alain');
      await service.activerGalerie(alain);
      await service.activer(alain);

      final List<dynamic> sansAlain = (jsonDecode(galeriesReelles) as List)
          .where((g) => g['nom'] != 'Alain')
          .toList();
      await service.actualiserGaleries(
          telecharger: () async => jsonEncode(sansAlain));
      expect(service.sources.value, [spiphoto]);
      expect(service.sourceActive.value, spiphoto);
    });

    test('réponse illisible : liste et sources inchangées', () async {
      SharedPreferences.setMockInitialValues({});
      await service.init();
      await service.actualiserGaleries(telecharger: reelles);
      await expectLater(
          service.actualiserGaleries(
              telecharger: () async => '<html>503</html>'),
          throwsFormatException);
      expect(service.galeriesAdherents.value, hasLength(8));
    });

    test(
        'désactiver ; spiphoto.fr ni retirable ni remplaçable par une inconnue',
        () async {
      SharedPreferences.setMockInitialValues({});
      await service.init();
      await service.actualiserGaleries(telecharger: reelles);
      final SourceConfig colin =
          service.galeriesAdherents.value.firstWhere((g) => g.nom == 'Colin');
      await service.activerGalerie(colin);
      await service.desactiverGalerie(colin);
      await service.retirer(spiphoto);
      await service.activer(colin); // n'est plus dans les sources
      await service.activerGalerie(
          galerie('X', TypeSource.piwigo, 'https://x.exemple.fr/'));
      expect(service.sources.value, [spiphoto]);
      expect(service.sourceActive.value, spiphoto);
    });
  });
}
