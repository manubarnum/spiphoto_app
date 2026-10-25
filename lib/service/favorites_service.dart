import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spiphoto_app/service/image_wp_info.dart' show stripWpImageSize;

/// Gère les favoris de l'utilisateur connecté, stockés dans Firestore.
///
/// Modèle de données (voir firestore.rules) :
///   favoriteEvents/{uid}_{mediaId}   — un document par favori individuel
///       { userId, mediaId, photoUrl, createdAt }
///   photoStats/{mediaId}.favoriteCount — compteur agrégé par photo,
///       partagé entre tous les utilisateurs.
///
/// L'ajout et le retrait touchent les deux collections dans une seule
/// transaction Firestore pour garantir qu'un événement favori et le
/// compteur associé restent toujours cohérents entre eux.
class FavoritesService {
  // ── Singleton, même logique que pour AuthService ──────────────────────
  FavoritesService._internal();
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

  /// Dérive un identifiant stable et unique pour une photo à partir de son
  /// URL. L'app n'a pas d'ID WordPress natif disponible (les albums sont
  /// extraits par scraping HTML, pas via l'API média) — on encode donc
  /// l'URL complète (suffixe de taille WordPress retiré, voir
  /// acces_wordpress.dart) en un identifiant Firestore valide.
  String _mediaIdFor(String photoUrl) =>
      Uri.encodeComponent(stripWpImageSize(photoUrl));

  /// Flux TEMPS RÉEL de la liste des URLs favorites.
  /// À utiliser avec un StreamBuilder dans favoris_screen.dart : dès qu'un
  /// favori est ajouté ou retiré (même depuis un autre écran de l'app),
  /// ce flux émet automatiquement la nouvelle liste.
  /// Retourne un flux vide si personne n'est connecté.
  ///
  /// Les favoris sont triés du plus récent au plus ancien (createdAt). Le
  /// tri se fait ici plutôt que par orderBy() : combiné au where() sur
  /// userId, il exigerait un index composite Firestore. Un favori tout juste
  /// ajouté n'a pas encore son horodatage serveur (null) : il passe en tête.
  Stream<List<String>> watchFavorites() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();

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
      return docs.map((doc) => doc.data()['photoUrl'] as String).toList();
    });
  }

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
  ///   on ne réincrémente pas le compteur une seconde fois.
  /// - favoriteEvents et photoStats sont écrits dans la même transaction :
  ///   soit les deux réussissent, soit aucun n'est modifié.
  Future<void> addFavorite(String photoUrl) async {
    final uid = _uid;
    if (uid == null) return;

    final String mediaId = _mediaIdFor(photoUrl);
    final eventRef = _eventsCollection.doc('${uid}_$mediaId');
    final statsRef = _statsCollection.doc(mediaId);

    await _db.runTransaction((transaction) async {
      final eventSnapshot = await transaction.get(eventRef);
      if (eventSnapshot.exists) return; // déjà favori — idempotent

      transaction.set(eventRef, {
        'userId': uid,
        'mediaId': mediaId,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.set(
        statsRef,
        {'favoriteCount': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
    });
  }

  /// Retire une photo des favoris.
  /// - Idempotent : si aucun événement n'existe pour cette photo, rien à
  ///   faire (pas d'erreur si la photo n'était pas favorite).
  /// - Le compteur est lu dans la transaction puis décrémenté manuellement
  ///   (jamais en dessous de 0) plutôt que via FieldValue.increment(-1), pour
  ///   pouvoir appliquer ce plancher.
  Future<void> removeFavorite(String photoUrl) async {
    final uid = _uid;
    if (uid == null) return;

    final String mediaId = _mediaIdFor(photoUrl);
    final eventRef = _eventsCollection.doc('${uid}_$mediaId');
    final statsRef = _statsCollection.doc(mediaId);

    await _db.runTransaction((transaction) async {
      final eventSnapshot = await transaction.get(eventRef);
      if (!eventSnapshot.exists) return; // pas favori — idempotent

      final statsSnapshot = await transaction.get(statsRef);
      final int currentCount =
          (statsSnapshot.data()?['favoriteCount'] as num?)?.toInt() ?? 0;
      final int newCount = currentCount > 0 ? currentCount - 1 : 0;

      transaction.delete(eventRef);
      transaction.set(
        statsRef,
        {'favoriteCount': newCount},
        SetOptions(merge: true),
      );
    });
  }

  /// Bascule l'état favori d'une photo : l'ajoute si elle est absente,
  /// la retire si elle est déjà favorite.
  Future<void> toggleFavorite(String photoUrl, bool isCurrentlyFavorite) async {
    if (isCurrentlyFavorite) {
      await removeFavorite(photoUrl);
    } else {
      await addFavorite(photoUrl);
    }
  }
}
