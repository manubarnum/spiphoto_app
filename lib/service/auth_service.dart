import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Exception levée quand un utilisateur se connecte avec un compte Google
/// qui n'appartient PAS au domaine @spiphoto.fr.
class AuthDomainException implements Exception {
  final String message;
  AuthDomainException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  // Client OAuth Web (client_type: 3). C'est lui qui sert d'audience pour
  // l'idToken vérifié par Firebase Auth — indispensable pour que
  // GoogleAuthProvider.credential() fonctionne derrière.
  //
  // On ne passe PAS le client Android (client_type: 1) à initialize() :
  // sur Android, le plugin le lit automatiquement depuis
  // google-services.json. Lui donner explicitement le mauvais type de
  // client (Android au lieu de Web) casse la config OAuth avec l'erreur
  // "[28444] Developer console is not set up correctly" — c'était le bug.
  static const String _webClientId =
      '786434708412-nkq6g3n3otukkbtovht2o1sv5oj8mtbl.apps.googleusercontent.com';

  static const String _allowedDomain = 'spiphoto.fr';

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // ── v7 : singleton fourni par le package, plus de constructeur direct ──
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _initialized = false;

  /// Doit être appelée une seule fois avant tout usage de _googleSignIn
  /// (authenticate, signOut, etc.). C'est LE changement principal de la v7 :
  /// initialize() est asynchrone et obligatoire — contrairement à v6 où
  /// tout se faisait implicitement au premier appel.
  ///
  /// Appelée depuis main.dart au démarrage de l'app (avant runApp, ou juste
  /// après Firebase.initializeApp()).
  Future<void> initialize() async {
    if (_initialized) return;
    await _googleSignIn.initialize(serverClientId: _webClientId);
    _initialized = true;
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  /// Lance le flux de connexion Google complet :
  /// 1. Ouvre le sélecteur de compte (Credential Manager en v7)
  /// 2. Vérifie que l'email se termine bien par @spiphoto.fr
  /// 3. Connecte l'utilisateur à Firebase Auth avec ce compte
  ///
  /// Différence clé avec v6 : authenticate() lève une GoogleSignInException
  /// en cas d'annulation (code .canceled) au lieu de retourner null.
  /// On distingue ce cas pour ne PAS le traiter comme une vraie erreur.
  Future<User?> signInWithGoogle() async {
    if (!_initialized) {
      throw StateError(
        'AuthService.initialize() doit être appelé avant signInWithGoogle() '
        '(normalement fait dans main.dart au démarrage).',
      );
    }

    final GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // L'utilisateur a fermé le sélecteur sans choisir de compte :
        // ce n'est pas une erreur, on retourne simplement null comme en v6.
        return null;
      }
      // Toute autre exception (ex. ApiException 10 sous-jacente) remonte
      // telle quelle pour être affichée par l'appelant.
      rethrow;
    }

    final email = googleUser.email;
    if (!email.toLowerCase().endsWith('@$_allowedDomain')) {
      await _googleSignIn.signOut();
      throw AuthDomainException(
        'Seuls les comptes @$_allowedDomain peuvent se connecter.',
      );
    }

    // v7 : .authentication est maintenant un getter SYNCHRONE (plus de
    // await) et ne fournit plus que l'idToken — l'accessToken doit être
    // demandé séparément via authorizationClient si besoin. Pour Firebase
    // Auth, l'idToken seul suffit.
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    if (googleAuth.idToken == null) {
      throw AuthDomainException('Impossible de récupérer le jeton Google.');
    }

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    return userCredential.user;
  }

  /// Connexion Google pour les écrans : renvoie null en cas de succès, ou le
  /// message d'erreur à afficher. L'affichage reste à la charge de la vue.
  Future<String?> connecterAvecGoogle() async {
    try {
      await signInWithGoogle();
      return null;
    } on AuthDomainException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('DEBUG AUTH ERROR: $e');
      return 'Échec de la connexion. Réessaie.';
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }
}
