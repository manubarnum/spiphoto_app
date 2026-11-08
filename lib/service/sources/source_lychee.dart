import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:spiphoto_app/service/image_wp_info.dart';
import 'package:spiphoto_app/service/sources/modeles.dart';
import 'package:spiphoto_app/service/sources/source_photos.dart';

/// Galerie Lychee 6 ou plus (API `/api/v2`), lue en visiteur : albums
/// publics seulement, sans favoris.
///
/// L'API exige une session, même pour un visiteur : un premier GET de la
/// page d'accueil donne les cookies `lychee_session` et `XSRF-TOKEN` ;
/// chaque appel renvoie ces cookies et le jeton dans `X-XSRF-TOKEN`.
/// Une réponse 419 (session expirée) relance la session une fois.
class SourceLychee extends SourcePhotos {
  @override
  final SourceConfig config;

  /// Profondeur maximale des sous-albums parcourus.
  static const int profondeurMax = 3;

  final http.Client _client;
  Uri? _base;
  final Map<String, String> _cookies = {};
  List<Album>? _albums;

  SourceLychee(this.config, {http.Client? client})
      : _client = client ?? http.Client();

  @override
  bool get favorisPossibles => false;

  /// Les albums sont aplatis : pas de filtre par catégorie.
  @override
  Future<List<Categorie>> categories() async => const [];

  @override
  Future<PageAlbums> albums({int page = 1, String? categorieId}) async {
    if (page == 1 || _albums == null) {
      final Object? racine = await _appel('Albums');
      final Uri base = _base!;
      _albums = await albumsAplatis(
        albumsRacineDepuisJson(racine),
        (id) => _sousAlbums(id),
        base,
      );
    }
    return pageDepuisListe(_albums!, page);
  }

  @override
  Future<List<ImageWpInfo>> photos(Album album) async {
    final List<ImageWpInfo> photos = [];
    // Pages à partir de 1 ; plafond de sécurité à 20 pages (2 000 photos).
    for (int page = 1; page <= 20; page++) {
      final Object? json = await _appel(
          'Album::photos', {'album_id': album.id, 'page': '$page'});
      photos.addAll(photosDepuisJson(json, album.title, _base!));
      if (page >= _dernierePage(json)) break;
    }
    return photos;
  }

  Future<List<Map<String, dynamic>>> _sousAlbums(String id) async {
    final List<Map<String, dynamic>> enfants = [];
    for (int page = 1; page <= 10; page++) {
      final Object? json =
          await _appel('Album::albums', {'album_id': id, 'page': '$page'});
      final Object? data = json is Map ? json['data'] : null;
      if (data is List) enfants.addAll(data.whereType<Map<String, dynamic>>());
      if (page >= _dernierePage(json)) break;
    }
    return enfants;
  }

  // ───────────────────────────────────────────────────────────────────────
  // SESSION ET APPELS
  // ───────────────────────────────────────────────────────────────────────

  Map<String, String> get _entetes => {
        'User-Agent': userAgentSources,
        if (_cookies.isNotEmpty)
          'Cookie':
              _cookies.entries.map((c) => '${c.key}=${c.value}').join('; '),
      };

  /// Ouvre la session sur la page d'accueil, en suivant les redirections
  /// (une galerie peut être installée sous `/public/`) : l'adresse finale
  /// devient la base de l'API.
  Future<void> _ouvrirSession() async {
    _cookies.clear();
    Uri adresse = racineSource(config.adresse);
    for (int saut = 0; saut < 5; saut++) {
      final http.Request requete = http.Request('GET', adresse)
        ..followRedirects = false
        ..headers.addAll(_entetes);
      final http.StreamedResponse reponse =
          await _client.send(requete).timeout(const Duration(seconds: 15));
      await reponse.stream.drain<void>();
      _cookies.addAll(cookiesDepuisEntete(reponse.headers['set-cookie']));
      final String? location = reponse.headers['location'];
      if (reponse.isRedirect && location != null) {
        adresse = racineSource(adresse.resolve(location));
        continue;
      }
      if (reponse.statusCode != 200) {
        throw Exception('Galerie Lychee injoignable (${reponse.statusCode})');
      }
      _base = adresse;
      return;
    }
    throw Exception('Galerie Lychee : trop de redirections');
  }

  Future<Object?> _appel(String route,
      [Map<String, String>? parametres]) async {
    if (_base == null || !_cookies.containsKey('XSRF-TOKEN')) {
      await _ouvrirSession();
    }
    for (int essai = 0; essai < 2; essai++) {
      final Uri uri =
          _base!.resolve('api/v2/$route').replace(queryParameters: parametres);
      final response = await _client.get(uri, headers: {
        ..._entetes,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-XSRF-TOKEN': Uri.decodeComponent(_cookies['XSRF-TOKEN'] ?? ''),
      }).timeout(const Duration(seconds: 15));
      _cookies.addAll(cookiesDepuisEntete(response.headers['set-cookie']));
      if (response.statusCode == 419 && essai == 0) {
        await _ouvrirSession();
        continue;
      }
      if (response.statusCode != 200) {
        throw Exception('Galerie Lychee en erreur (${response.statusCode})');
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Galerie Lychee : session refusée');
  }

  // ───────────────────────────────────────────────────────────────────────
  // LECTURE DES RÉPONSES (fonctions pures, testées)
  // ───────────────────────────────────────────────────────────────────────

  /// Cookies d'un en-tête `set-cookie`. Le client HTTP joint les en-têtes
  /// multiples par des virgules, que l'on retrouve aussi dans les dates
  /// (`expires=Sun, 08-Nov-2026…`) : on ne coupe qu'avant un `nom=`.
  static Map<String, String> cookiesDepuisEntete(String? entete) {
    if (entete == null || entete.isEmpty) return const {};
    final Map<String, String> cookies = {};
    for (final String cookie
        in entete.split(RegExp(r',(?=\s*[A-Za-z0-9_\-]+=)'))) {
      final String paire = cookie.split(';').first.trim();
      final int egal = paire.indexOf('=');
      if (egal <= 0) continue;
      final String nom = paire.substring(0, egal);
      // Attributs isolés par la découpe (expires=…, path=…) : ignorés.
      if (const {'expires', 'path', 'domain', 'max-age', 'samesite'}
          .contains(nom.toLowerCase())) {
        continue;
      }
      cookies[nom] = paire.substring(egal + 1);
    }
    return cookies;
  }

  /// Albums de premier niveau (`Albums`) : albums propres et albums
  /// partagés par d'autres comptes ; les albums « intelligents », par
  /// étiquette ou par personne sont ignorés.
  static List<Map<String, dynamic>> albumsRacineDepuisJson(Object? json) {
    if (json is! Map) return const [];
    final Set<String> vus = {};
    return [
      for (final String cle in const ['albums', 'shared_albums'])
        if (json[cle] is List)
          ...(json[cle] as List).whereType<Map<String, dynamic>>(),
    ].where((a) => a['id'] is String && vus.add(a['id'] as String)).toList();
  }

  /// Liste à plat : un album à sous-albums est remplacé par ses enfants
  /// (« Parent › Enfant »), gardé lui-même seulement s'il annonce des
  /// photos. Le nombre de photos annoncé n'est pas fiable (0 sur des
  /// albums qui en contiennent) : un album sans sous-album est toujours
  /// gardé.
  static Future<List<Album>> albumsAplatis(
    List<Map<String, dynamic>> albums,
    Future<List<Map<String, dynamic>>> Function(String id) sousAlbums,
    Uri base, {
    String? parent,
    int profondeur = 0,
  }) async {
    final List<Album> resultat = [];
    for (final Map<String, dynamic> json in albums) {
      final String? id = json['id'] is String ? json['id'] as String : null;
      if (id == null) continue;
      final String titre = (json['title'] as String? ?? '').trim();
      final String titreComplet = parent == null ? titre : '$parent › $titre';
      final bool aDesEnfants = json['has_subalbum'] == true;
      final int nbPhotos = _entier(json['num_photos']);
      if (!aDesEnfants || nbPhotos > 0) {
        resultat.add(albumDepuisJson(json, base, titre: titreComplet));
      }
      if (aDesEnfants && profondeur < profondeurMax) {
        resultat.addAll(await albumsAplatis(
          await sousAlbums(id),
          sousAlbums,
          base,
          parent: titreComplet,
          profondeur: profondeur + 1,
        ));
      }
    }
    return resultat;
  }

  /// Un album de la liste ; ses photos sont chargées à l'ouverture.
  static Album albumDepuisJson(Map<String, dynamic> json, Uri base,
      {String? titre}) {
    final Object? thumb = json['thumb'];
    final String? petite = thumb is Map ? _url(thumb['thumb'], base) : null;
    final String? grande =
        thumb is Map ? _url(thumb['thumb2x'], base) ?? petite : null;
    final String nom = titre ?? (json['title'] as String? ?? '').trim();
    final int nbPhotos = _entier(json['num_photos']);
    return Album(
      id: json['id'] as String,
      title: nom,
      images: const [],
      nbPhotosAnnonce: nbPhotos > 0 ? nbPhotos : null,
      couverture: grande == null
          ? null
          : ImageWpInfo(
              mediaId: null,
              thumbnailUrl: grande,
              ecranUrl: grande,
              landscapeUrl: grande,
              description: nom,
            ),
    );
  }

  /// Photos de `Album::photos` (les vidéos sont ignorées).
  static List<ImageWpInfo> photosDepuisJson(
      Object? json, String titreAlbum, Uri base) {
    final Object? photos = json is Map ? json['photos'] : null;
    if (photos is! List) return const [];
    return photos
        .whereType<Map<String, dynamic>>()
        .where((p) => !'${p['type'] ?? ''}'.startsWith('video/'))
        .map((p) {
          final Object? variantes = p['size_variants'];
          String? taille(String nom) => variantes is Map
              ? _url(
                  (variantes[nom] is Map ? variantes[nom]['url'] : null), base)
              : null;
          // Original souvent refusé aux visiteurs (url null) : la plus
          // grande taille disponible le remplace.
          final String? original = taille('original') ??
              taille('medium2x') ??
              taille('medium') ??
              taille('small2x') ??
              taille('small');
          if (original == null) return null;
          return ImageWpInfo(
            mediaId: null,
            thumbnailUrl: taille('thumb2x') ?? taille('thumb') ?? original,
            ecranUrl: taille('medium') ?? taille('small2x') ?? original,
            landscapeUrl: original,
            description: titreAlbum,
          );
        })
        .whereType<ImageWpInfo>()
        .toList();
  }

  static int _dernierePage(Object? json) =>
      json is Map ? (_entier(json['last_page']).clamp(1, 1000)) : 1;

  static int _entier(Object? valeur) => valeur is int
      ? valeur
      : valeur is String
          ? int.tryParse(valeur) ?? 0
          : 0;

  /// URL absolue (les adresses de Lychee peuvent être relatives), hors
  /// `data:` (aperçus flous intégrés).
  static String? _url(Object? valeur, Uri base) {
    if (valeur is! String || valeur.isEmpty || valeur.startsWith('data:')) {
      return null;
    }
    return base.resolve(valeur).toString();
  }
}
