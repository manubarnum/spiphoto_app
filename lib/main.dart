import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/interface/appbar_accueil.dart';
import '/interface/album_list.dart';
import '/interface/album_details_screen.dart';
import '/interface/favoris_screen.dart';
import '/interface/club_screen.dart';
import 'package:spiphoto_app/service/acces_wordpress.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Barre de statut transparente — immersif magazine
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

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

// ─────────────────────────────────────────────────────────────────────────────
// APPLICATION
// ─────────────────────────────────────────────────────────────────────────────
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SPIPHOTO',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const ScaffoldWithNavigation(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // ── Couleurs ────────────────────────────────────────────────────────
      colorScheme: const ColorScheme.dark(
        primary: SpiColors.olive,
        onPrimary: SpiColors.texte,
        primaryContainer: SpiColors.oliveFonce,
        onPrimaryContainer: SpiColors.texte,
        secondary: SpiColors.mauve,
        onSecondary: SpiColors.texte,
        secondaryContainer: SpiColors.mauveFonce,
        onSecondaryContainer: SpiColors.texte,
        surface: SpiColors.surface,
        onSurface: SpiColors.texte,
        surfaceContainerHighest: SpiColors.surfaceAlt,
        error: SpiColors.erreur,
        onError: SpiColors.texte,
      ),

      scaffoldBackgroundColor: SpiColors.noir,

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: SpiColors.surface,
        foregroundColor: SpiColors.texte,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: SpiColors.texte,
          fontSize: 16.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 3.0, // effet magazine éditorial
        ),
        iconTheme: IconThemeData(
          color: SpiColors.texte,
          size: 24.0,
        ),
      ),

      // ── BottomNavigationBar ─────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SpiColors.surface,
        selectedItemColor: SpiColors.mauve, // mauve pour l'actif
        unselectedItemColor: SpiColors.texteMuted,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 11,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // ── Cards ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: SpiColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: SpiColors.surfaceAlt,
        thickness: 1,
        space: 1,
      ),

      // ── Icons ────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: SpiColors.texte,
        size: 24.0,
      ),

      // ── ProgressIndicator ────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: SpiColors.mauve,
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: SpiColors.surfaceHigh,
        contentTextStyle: TextStyle(color: SpiColors.texte),
        actionTextColor: SpiColors.mauveClair,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),

      // ── Chips (pour filtres futurs) ──────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: SpiColors.surfaceAlt,
        selectedColor: SpiColors.oliveFonce,
        labelStyle: const TextStyle(color: SpiColors.texte, fontSize: 13),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // ── Typographie ──────────────────────────────────────────────────────
      textTheme: const TextTheme(
        // Grands titres — nom d'album en détail
        headlineMedium: TextStyle(
          color: SpiColors.texte,
          fontSize: 26.0,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          height: 1.2,
        ),
        headlineSmall: TextStyle(
          color: SpiColors.texte,
          fontSize: 22.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
        // Titres de cartes
        titleLarge: TextStyle(
          color: SpiColors.texte,
          fontSize: 17.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
        titleMedium: TextStyle(
          color: SpiColors.texte,
          fontSize: 15.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        titleSmall: TextStyle(
          color: SpiColors.texte,
          fontSize: 13.0,
          fontWeight: FontWeight.w600,
        ),
        // Corps de texte
        bodyLarge: TextStyle(
          color: SpiColors.texte,
          fontSize: 15.0,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: SpiColors.texte,
          fontSize: 13.0,
          height: 1.4,
        ),
        // Textes secondaires — date, nb photos…
        bodySmall: TextStyle(
          color: SpiColors.texteMuted,
          fontSize: 12.0,
          letterSpacing: 0.4,
        ),
        labelSmall: TextStyle(
          color: SpiColors.texteMuted,
          fontSize: 10.0,
          letterSpacing: 1.0,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NAVIGATION PRINCIPALE — 3 ONGLETS
// ─────────────────────────────────────────────────────────────────────────────
class ScaffoldWithNavigation extends StatefulWidget {
  const ScaffoldWithNavigation({super.key});

  @override
  State<ScaffoldWithNavigation> createState() => _ScaffoldWithNavigationState();
}

class _ScaffoldWithNavigationState extends State<ScaffoldWithNavigation> {
  int _currentIndex = 0;

  // Clés pour conserver l'état de chaque onglet (Navigator indépendant)
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  // Intercepte le bouton retour Android — navigue dans l'onglet actif
  bool _onPopInvoked() {
    final NavigatorState? navigator =
        _navigatorKeys[_currentIndex].currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return false; // ne ferme pas l'app
    }
    return true; // ferme l'app si rien à dépiler
  }

  Widget _buildNavigator(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        if (settings.name == '/album_details_screen') {
          final album = settings.arguments as Album;
          return MaterialPageRoute(
            builder: (_) => AlbumDetailsScreen(album: album),
          );
        }
        return MaterialPageRoute(builder: (_) => child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // canPop: false bloque le retour système,
      // onPopInvokedWithResult gère la logique manuellement
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onPopInvoked();
      },
      child: Scaffold(
        appBar: const MyAppBarAccueil(),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            // Onglet 0 — Albums
            _buildNavigator(0, const MyList()),
            // Onglet 1 — Mes Favoris
            _buildNavigator(1, const FavorisScreen()),
            // Onglet 2 — Club
            _buildNavigator(2, const ClubScreen()),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.photo_library_outlined),
              activeIcon: Icon(Icons.photo_library),
              label: 'Albums',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: 'Mes favoris',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups),
              label: 'Club',
            ),
          ],
        ),
      ),
    );
  }
}
