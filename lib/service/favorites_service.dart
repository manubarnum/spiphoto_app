import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';

/// Gère les favoris de l'utilisateur connecté, stockés dans Firestore.
///
/// Modèle de données (voir firestore.rules) :
///   favoriteEvents/{uid}_{mediaId}   — un document par favori individuel
///       { userId, mediaId, photoUrl, vignetteUrl, ecranUrl, createdAt }
///   photoStats/{mediaId} — une fiche par photo, partagée entre tous les
///       utilisateurs : compteur favoriteCount, et de quoi afficher le fil
///       du Club sans relire les événements (photoUrl, vignetteUrl, ecranUrl,
///       albumTitle, lastAddedAt, membres.{uid}: {nom, photo, ajout}).
/// mediaId est l'identifiant du média WordPress (voir ImageWpInfo.mediaId).
///
/// L'ajout et le retrait touchent les deux collections dans un seul lot
/// d'écritures (WriteBatch), sans lecture préalable : l'événement favori et
/// la fiche restent cohérents, et l'écriture part même hors ligne (elle est
/// envoyée au retour du réseau).
class FavoritesService {
  // ── Singleton, même logique que pour AuthService ──────────────────────
  FavoritesService._internal() {
    // Changement de compte : l'abonnement aux favoris de l'ancien compte est
    // fermé ; celui du nouveau s'ouvrira au premier écran qui le demande.
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user?.uid != _uidAbonne) _fermerAbonnement();
    });
  }
  static final FavoritesService instance = FavoritesService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _db.collection('favoriteEvents');
  CollectionReference<Map<String, dynamic>> get _statsCollection =>
      _db.collection('photoStats');

  // Identifiant de l'utilisateur connecté (null si personne connecté).
  // On le relit à chaque appel plutôt que de le stocker, pour être sûr
  // d'avoir toujours la valeur à jour si l'utilisateur se déconnecte/reconnecte.
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  final ValueNotifier<List<ImageWpInfo>?> _favoris = ValueNotifier(null);
  StreamSubscription<List<ImageWpInfo>>? _abonnement;
  String? _uidAbonne;

  /// Photos favorites de l'utilisateur connecté, tenues à jour en TEMPS
  /// RÉEL : dès qu'un favori est ajouté ou retiré (depuis n'importe quel
  /// écran), la liste change. null tant que la première liste n'est pas
  /// arrivée, ou si personne n'est connecté.
  ///
  /// Un seul abonnement Firestore, partagé par tous les écrans (Mes favoris,
  /// Club, visionneuse) : ouvert au premier accès, gardé jusqu'au changement
  /// de compte. Ouvrir et fermer la visionneuse ne relance donc aucune
  /// requête.
  ValueListenable<List<ImageWpInfo>?> get favoris {
    final uid = _uid;
    if (uid != null && _abonnement == null) {
      _uidAbonne = uid;
      _abonnement = _requeteFavoris(uid).listen(
        (photos) => _favoris.value = photos,
        // Lecture refusée ou réseau absent : liste vide plutôt qu'un
        // chargement sans fin.
        onError: (Object _) => _favoris.value ??= const [],
      );
    }
    return _favoris;
  }

  void _fermerAbonnement() {
    _abonnement?.cancel();
    _abonnement = null;
    _uidAbonne = null;
    _favoris.value = null;
  }

  /// Les favoris sont triés du plus récent au plus ancien (createdAt). Le
  /// tri se fait ici plutôt que par orderBy() : combiné au where() sur
  /// userId, il exigerait un index composite Firestore. Un favori tout juste
  /// ajouté n'a pas encore son horodatage serveur (null) : il passe en tête.
  Stream<List<ImageWpInfo>> _requeteFavoris(String uid) {
    return _eventsCollection
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs
          .where((doc) => doc.data()['photoUrl'] is String)
          .toList();
      docs.sort((a, b) {
        final Timestamp? dateA = a.data()['createdAt'] as Timestamp?;
        final Timestamp? dateB = b.data()['createdAt'] as Timestamp?;
        if (dateA == null) return dateB == null ? 0 : -1;
        if (dateB == null) return 1;
        return dateB.compareTo(dateA);
      });
      return docs.map((doc) => _photoFavorite(doc.data())).toList();
    });
  }

  // Les favoris enregistrés par les versions précédentes de l'app n'ont que
  // photoUrl : fromFavoriteUrl reconstruit alors la vignette.
  static ImageWpInfo _photoFavorite(Map<String, dynamic> data) =>
      ImageWpInfo.fromFavoriteUrl(
        data['photoUrl'] as String,
        mediaId: data['mediaId'] as String?,
        thumbnailUrl: data['vignetteUrl'] as String?,
        ecranUrl: data['ecranUrl'] as String?,
        album: data['albumTitle'] as String?,
      );

  /// Lecture PONCTUELLE (une seule fois, pas de mise à jour automatique).
  /// Utile quand on veut juste vérifier une valeur sans "écouter" en continu.
  Future<List<String>> getFavoritesOnce() async {
    final uid = _uid;
    if (uid == null) return <String>[];

    final snapshot =
        await _eventsCollection.where('userId', isEqualTo: uid).get();
    return snapshot.docs
        .map((doc) => doc.data()['photoUrl'] as String?)
        .whereType<String>()
        .toList();
  }

  /// Vérifie si une photo donnée est déjà dans les favoris.
  /// Utilisé pour savoir si le cœur doit être plein ou vide au chargement
  /// de la visionneuse plein écran.
  Future<bool> isFavorite(String photoUrl) async {
    final favorites = await getFavoritesOnce();
    return favorites.contains(photoUrl);
  }

  /// Ajoute une photo aux favoris.
  /// - Ne fait rien si personne n'est connecté (sécurité silencieuse).
  /// - Idempotent : si l'événement existe déjà (double appel, tap répété),
  ///   le recréer serait une modification, que les règles refusent ; tout le
  ///   lot est alors rejeté et le compteur n'est pas réincrémenté.
  /// - favoriteEvents et photoStats sont écrits dans le même lot : soit les
  ///   deux réussissent, soit aucun n'est modifié.
  /// - Le nom, l'avatar du membre et l'album (si connu) sont copiés dans
  ///   l'événement et dans la fiche photoStats pour le fil du Club : aucun
  ///   profil membre n'existe ailleurs dans Firestore. Un changement de nom
  ///   ultérieur n'est pas répercuté.
  Future<void> addFavorite(ImageWpInfo photo, {String? albumTitle}) async {
    final User? user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (uid == null) return;

    final String mediaId = photo.mediaId;
    final eventRef = _eventsCollection.doc('${uid}_$mediaId');
    final statsRef = _statsCollection.doc(mediaId);

    final WriteBatch lot = _db.batch()
      ..set(eventRef, {
        'userId': uid,
        'mediaId': mediaId,
        'photoUrl': photo.landscapeUrl,
        'vignetteUrl': photo.thumbnailUrl,
        'ecranUrl': photo.ecranUrl,
        'createdAt': FieldValue.serverTimestamp(),
        if (user?.displayName != null) 'userName': user!.displayName,
        if (user?.photoURL != null) 'userPhoto': user!.photoURL,
        if (albumTitle != null) 'albumTitle': albumTitle,
      })
      ..set(
        statsRef,
        {
          'favoriteCount': FieldValue.increment(1),
          'lastAddedAt': FieldValue.serverTimestamp(),
          'photoUrl': photo.landscapeUrl,
          'vignetteUrl': photo.thumbnailUrl,
          'ecranUrl': photo.ecranUrl,
          if (albumTitle != null) 'albumTitle': albumTitle,
          'membres': {
            uid: {
              'ajout': FieldValue.serverTimestamp(),
              if (user?.displayName != null) 'nom': user!.displayName,
              if (user?.photoURL != null) 'photo': user!.photoURL,
            },
          },
        },
        SetOptions(merge: true),
      );
    await _valider(lot);
  }

  /// Retire une photo des favoris.
  /// - Idempotent : si aucun événement n'existe pour cette photo, supprimer
  ///   l'événement est refusé par les règles et tout le lot est rejeté.
  /// - Le compteur est décrémenté sans être lu ; les règles l'empêchent de
  ///   passer sous 0.
  /// - Le membre sort de la fiche photoStats. La date du dernier ajout ne
  ///   change pas : une photo revenue à 0 favori est écartée du fil par son
  ///   compteur.
  Future<void> removeFavorite(ImageWpInfo photo) async {
    final uid = _uid;
    if (uid == null) return;

    final String mediaId = photo.mediaId;
    final eventRef = _eventsCollection.doc('${uid}_$mediaId');
    final statsRef = _statsCollection.doc(mediaId);

    final WriteBatch lot = _db.batch()
      ..delete(eventRef)
      ..set(
        statsRef,
        {
          'favoriteCount': FieldValue.increment(-1),
          'membres': {uid: FieldValue.delete()},
        },
        SetOptions(merge: true),
      );
    await _valider(lot);
  }

  // Un lot refusé par les règles est le cas « déjà favori » (ou « pas
  // favori ») : rien n'a été écrit, comme le veut l'idempotence. Les autres
  // erreurs remontent à l'appelant.
  static Future<void> _valider(WriteBatch lot) async {
    try {
      await lot.commit();
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }
  }

  /// Bascule l'état favori d'une photo : l'ajoute si elle est absente,
  /// la retire si elle est déjà favorite.
  Future<void> toggleFavorite(ImageWpInfo photo, bool isCurrentlyFavorite,
      {String? albumTitle}) async {
    if (isCurrentlyFavorite) {
      await removeFavorite(photo);
    } else {
      await addFavorite(photo, albumTitle: albumTitle);
    }
  }

  /// Fil « Les favoris du Club », selon [tri] :
  /// - [TriClub.plusChoisies] : par nombre de favoris décroissant (tri sur
  ///   favoriteCount) ;
  /// - [TriClub.dernieres] : la photo mise en favori le plus récemment en
  ///   tête (tri sur lastAddedAt). Les photos revenues à 0 favori gardent
  ///   leur date : on en lit deux fois plus, puis on les écarte.
  /// Une seule requête sur photoStats, dont les fiches portent tout le
  /// nécessaire à l'affichage. Les deux tris ne reposent que sur des index
  /// simples, créés automatiquement.
  Future<List<FavoriClub>> getFavorisDuClub({
    TriClub tri = TriClub.plusChoisies,
    int limite = 20,
  }) async {
    if (_uid == null) return <FavoriClub>[];

    final Query<Map<String, dynamic>> requete = tri == TriClub.plusChoisies
        ? _statsCollection
            .where('favoriteCount', isGreaterThan: 0)
            .orderBy('favoriteCount', descending: true)
        : _statsCollection.orderBy('lastAddedAt', descending: true);
    final stats = await requete
        .limit(tri == TriClub.plusChoisies ? limite : limite * 2)
        .get();

    // Les fiches écrites par les versions précédentes de l'app n'ont que le
    // compteur : leur entrée est alors reconstruite à partir des événements.
    final List<FavoriClub> fil = (await Future.wait(stats.docs.map((doc) =>
            doc.data()['photoUrl'] is String
                ? Future.value(favoriClubDepuisFiche(doc.id, doc.data()))
                : _favoriClub(doc.id))))
        .whereType<FavoriClub>()
        .where((f) => f.nbFavoris > 0)
        .take(limite)
        .toList();

    // On retrie sur les valeurs affichées : une entrée reconstruite peut
    // différer de la fiche.
    if (tri == TriClub.plusChoisies) {
      fil.sort((a, b) => b.nbFavoris.compareTo(a.nbFavoris));
    } else {
      fil.sort((a, b) => _comparerDates(b.dernierAjout, a.dernierAjout));
    }
    return fil;
  }

  /// Une entrée du fil à partir de la fiche photoStats d'une photo.
  @visibleForTesting
  static FavoriClub favoriClubDepuisFiche(
      String mediaId, Map<String, dynamic> data) {
    final Object? membres = data['membres'];
    // Premiers membres à l'avoir choisie en tête de la liste.
    final List<Map<String, dynamic>> entrees = membres is Map
        ? (membres.values
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList()
          ..sort((a, b) => _comparerDates((a['ajout'] as Timestamp?)?.toDate(),
              (b['ajout'] as Timestamp?)?.toDate())))
        : [];

    return FavoriClub(
      mediaId: mediaId,
      photoUrl: data['photoUrl'] as String,
      vignetteUrl: data['vignetteUrl'] as String?,
      ecranUrl: data['ecranUrl'] as String?,
      nbFavoris: (data['favoriteCount'] as num?)?.toInt() ?? 0,
      dernierAjout: (data['lastAddedAt'] as Timestamp?)?.toDate(),
      membres: entrees
          .where((m) => m['nom'] is String)
          .map((m) => MembreFavori(
                nom: m['nom'] as String,
                photoUrl: m['photo'] as String?,
              ))
          .toList(),
      albumTitle: data['albumTitle'] as String?,
    );
  }

  /// Une entrée du fil à partir des événements favoris d'une photo (fiches
  /// photoStats des versions précédentes de l'app).
  Future<FavoriClub?> _favoriClub(String mediaId) async {
    final events =
        await _eventsCollection.where('mediaId', isEqualTo: mediaId).get();
    if (events.docs.isEmpty) return null;

    // Premiers membres à l'avoir choisie en tête de la liste.
    final docs = events.docs.toList()
      ..sort((a, b) => _comparerDates(
          (a.data()['createdAt'] as Timestamp?)?.toDate(),
          (b.data()['createdAt'] as Timestamp?)?.toDate()));
    final String? photoUrl =
        docs.map((d) => d.data()['photoUrl']).whereType<String>().firstOrNull;
    if (photoUrl == null) return null;

    return FavoriClub(
      mediaId: mediaId,
      photoUrl: photoUrl,
      vignetteUrl: docs
          .map((d) => d.data()['vignetteUrl'])
          .whereType<String>()
          .firstOrNull,
      ecranUrl:
          docs.map((d) => d.data()['ecranUrl']).whereType<String>().firstOrNull,
      nbFavoris: docs.length,
      dernierAjout: (docs.last.data()['createdAt'] as Timestamp?)?.toDate(),
      membres: docs
          .where((d) => d.data()['userName'] is String)
          .map((d) => MembreFavori(
                nom: d.data()['userName'] as String,
                photoUrl: d.data()['userPhoto'] as String?,
              ))
          .toList(),
      albumTitle: docs
          .map((d) => d.data()['albumTitle'])
          .whereType<String>()
          .firstOrNull,
    );
  }

  // Ordre chronologique ; une date absente (horodatage serveur pas encore
  // reçu, donc ajout tout juste fait) compte comme la plus récente.
  static int _comparerDates(DateTime? a, DateTime? b) {
    if (a == null) return b == null ? 0 : 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }
}

/// Ordre du fil du Club.
enum TriClub { plusChoisies, dernieres }

/// Une photo du fil du Club.
class FavoriClub {
  final String mediaId;
  final String photoUrl;

  /// Vignette et taille écran, absentes des favoris enregistrés par les
  /// versions précédentes de l'app.
  final String? vignetteUrl;
  final String? ecranUrl;
  final int nbFavoris;

  /// Membres dont le nom est connu (favoris enregistrés avec le profil),
  /// du premier au dernier à l'avoir choisie. Peut être plus court que
  /// [nbFavoris] : les favoris plus anciens n'ont pas de nom.
  final List<MembreFavori> membres;
  final String? albumTitle;

  /// Date du dernier ajout en favori (tri « dernières ajoutées »).
  final DateTime? dernierAjout;

  const FavoriClub({
    required this.mediaId,
    required this.photoUrl,
    required this.nbFavoris,
    this.vignetteUrl,
    this.ecranUrl,
    required this.membres,
    this.albumTitle,
    this.dernierAjout,
  });
}

class MembreFavori {
  final String nom;
  final String? photoUrl;

  const MembreFavori({required this.nom, this.photoUrl});
}
