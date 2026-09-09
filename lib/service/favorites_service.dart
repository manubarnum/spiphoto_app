import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Gère la liste des photos favorites de l'utilisateur connecté, stockée
/// dans Firestore.
///
/// Modèle de données choisi (le plus simple possible pour ton besoin) :
///   collection "favorites"
///     └── document {uid}          (un document par utilisateur)
///           champ "photos": [url1, url2, ...]   (tableau d'URLs)
///
/// Pas de sous-collection, pas de document par photo : un seul document
/// par utilisateur suffit puisqu'on ne stocke que des URLs (pas de
/// métadonnées par favori).
class FavoritesService {
  // ── Singleton, même logique que pour AuthService ──────────────────────
  FavoritesService._internal();
  static final FavoritesService instance = FavoritesService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Raccourci vers la collection "favorites".
  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('favorites');

  // Identifiant de l'utilisateur connecté (null si personne connecté).
  // On le relit à chaque appel plutôt que de le stocker, pour être sûr
  // d'avoir toujours la valeur à jour si l'utilisateur se déconnecte/reconnecte.
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Flux TEMPS RÉEL de la liste des URLs favorites.
  /// À utiliser avec un StreamBuilder dans favoris_screen.dart : dès qu'un
  /// favori est ajouté ou retiré (même depuis un autre écran de l'app),
  /// ce flux émet automatiquement la nouvelle liste.
  /// Retourne un flux vide si personne n'est connecté.
  Stream<List<String>> watchFavorites() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();

    return _collection.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return <String>[];
      final photos = data['photos'] as List<dynamic>?;
      return photos?.cast<String>() ?? <String>[];
    });
  }

  /// Lecture PONCTUELLE (une seule fois, pas de mise à jour automatique).
  /// Utile quand on veut juste vérifier une valeur sans "écouter" en continu.
  Future<List<String>> getFavoritesOnce() async {
    final uid = _uid;
    if (uid == null) return <String>[];

    final snapshot = await _collection.doc(uid).get();
    final data = snapshot.data();
    if (data == null) return <String>[];
    final photos = data['photos'] as List<dynamic>?;
    return photos?.cast<String>() ?? <String>[];
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
  /// - FieldValue.arrayUnion : ajoute la valeur SEULEMENT si elle n'est pas
  ///   déjà présente (pas de doublon possible).
  /// - SetOptions(merge: true) : crée le document s'il n'existe pas encore
  ///   (cas du tout premier favori d'un utilisateur), sinon met juste à jour
  ///   le champ "photos" sans écraser le reste du document.
  Future<void> addFavorite(String photoUrl) async {
    final uid = _uid;
    if (uid == null) return;

    await _collection.doc(uid).set(
      {
        'photos': FieldValue.arrayUnion([photoUrl])
      },
      SetOptions(merge: true),
    );
  }

  /// Retire une photo des favoris.
  /// FieldValue.arrayRemove : supprime la valeur si elle est présente,
  /// ne fait rien sinon (pas d'erreur si la photo n'était pas favorite).
  Future<void> removeFavorite(String photoUrl) async {
    final uid = _uid;
    if (uid == null) return;

    await _collection.doc(uid).update(
      {
        'photos': FieldValue.arrayRemove([photoUrl])
      },
    );
  }
}
  /// Bascule l'état favori d'une photo (ajoute si absente, retire si présente).
  ///