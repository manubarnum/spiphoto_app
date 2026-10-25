import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:extended_image/extended_image.dart';
import 'package:spiphoto_app/spi_colors.dart';
import 'package:spiphoto_app/interface/appbar_accueil.dart';
import 'package:spiphoto_app/interface/bottom_nav.dart';
import 'package:spiphoto_app/interface/album_list.dart';
import 'package:spiphoto_app/interface/album_details_screen.dart';
import 'package:spiphoto_app/interface/favoris_screen.dart';
import 'package:spiphoto_app/interface/club_screen.dart';
import 'package:spiphoto_app/service/acces_wordpress.dart';
import 'package:spiphoto_app/service/auth_service.dart';
import 'package:spiphoto_app/service/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AuthService.instance.initialize();
  await ThemeService.instance.init();
  // Cache disque des images (extended_image) : jamais purgé seul. On retire
  // les fichiers de plus de 30 jours, sans retarder le démarrage.
  unawaited(clearDiskCachedImages(duration: const Duration(days: 30)));
  // Barre de statut transparente — immersif magazine. La couleur des icônes
  // suit le thème (AppBarTheme.systemOverlayStyle).
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const MyApp());
}

// ─────────────────────────────────────────────────────────────────────────────
// APPLICATION
// ─────────────────────────────────────────────────────────────────────────────
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Jour / nuit : choix de l'utilisateur, sinon réglage de l'appareil.
    return ValueListenableBuilder<bool?>(
      valueListenable: ThemeService.instance.sombre,
      builder: (context, sombre, _) => MaterialApp(
        title: 'SPIPHOTO',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(SpiPalette.clair, Brightness.light),
        darkTheme: _buildTheme(SpiPalette.sombre, Brightness.dark),
        themeMode: switch (sombre) {
          true => ThemeMode.dark,
          false => ThemeMode.light,
          null => ThemeMode.system,
        },
        home: const ScaffoldWithNavigation(),
      ),
    );
  }

  ThemeData _buildTheme(SpiPalette p, Brightness luminosite) {
    final bool sombre = luminosite == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: luminosite,
      extensions: [p],

      // ── Couleurs ────────────────────────────────────────────────────────
      // L'olive et le texte crème posé dessus ne changent pas avec le thème.
      colorScheme: ColorScheme(
        brightness: luminosite,
        primary: SpiColors.olive,
        onPrimary: SpiColors.texte,
        primaryContainer: SpiColors.oliveFonce,
        onPrimaryContainer: SpiColors.texte,
        secondary: p.mauve,
        onSecondary: SpiColors.texte,
        secondaryContainer: SpiColors.mauveFonce,
        onSecondaryContainer: SpiColors.texte,
        surface: p.surface,
        onSurface: p.encre,
        onSurfaceVariant: p.encreSecondaire,
        surfaceContainerHighest: p.surfaceAlt,
        error: SpiColors.erreur,
        onError: SpiColors.texte,
      ),

      scaffoldBackgroundColor: p.fond,

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        foregroundColor: p.encre,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        // Icônes de la barre d'état lisibles sur la barre d'app
        systemOverlayStyle:
            sombre ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: p.encre,
          fontSize: 16.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 3.0, // effet magazine éditorial
        ),
        iconTheme: IconThemeData(
          color: p.encre,
          size: 24.0,
        ),
      ),

      // ── Cards ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: p.surfaceAlt,
        thickness: 1,
        space: 1,
      ),

      // ── Icons ────────────────────────────────────────────────────────────
      iconTheme: IconThemeData(
        color: p.encre,
        size: 24.0,
      ),

      // ── ProgressIndicator ────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.mauve,
      ),

      // ── BottomSheet (panneau « Mon compte ») ─────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        modalBackgroundColor: p.surface,
        dragHandleColor: p.encreTertiaire,
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceElevee,
        contentTextStyle: TextStyle(color: p.encre),
        actionTextColor: p.accent,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),

      // ── Chips (pour filtres futurs) ──────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceAlt,
        selectedColor: SpiColors.oliveFonce,
        labelStyle: TextStyle(color: p.encre, fontSize: 13),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // ── Typographie ──────────────────────────────────────────────────────
      textTheme: TextTheme(
        // Grands titres — nom d'album en détail
        headlineMedium: TextStyle(
          color: p.encre,
          fontSize: 26.0,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          height: 1.2,
        ),
        headlineSmall: TextStyle(
          color: p.encre,
          fontSize: 22.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
        // Titres de cartes
        titleLarge: TextStyle(
          color: p.encre,
          fontSize: 17.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
        titleMedium: TextStyle(
          color: p.encre,
          fontSize: 15.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        titleSmall: TextStyle(
          color: p.encre,
          fontSize: 13.0,
          fontWeight: FontWeight.w600,
        ),
        // Corps de texte
        bodyLarge: TextStyle(
          color: p.encre,
          fontSize: 15.0,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: p.encre,
          fontSize: 13.0,
          height: 1.4,
        ),
        // Textes secondaires — date, nb photos…
        bodySmall: TextStyle(
          color: p.encreSecondaire,
          fontSize: 12.0,
          letterSpacing: 0.4,
        ),
        labelSmall: TextStyle(
          color: p.encreSecondaire,
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

  // Onglets déjà ouverts. IndexedStack construit tous ses enfants : sans
  // cela, le fil du Club et l'écoute des favoris partiraient dès le
  // lancement, même si l'onglet n'est jamais ouvert.
  final Set<int> _ongletsVisites = {0};

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

  // Ramène un onglet à sa page racine (ex. d'un album vers la liste).
  void _revenirALaRacine(int index) {
    _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
  }

  void _afficherOnglet(int index) {
    setState(() {
      _currentIndex = index;
      _ongletsVisites.add(index);
    });
  }

  // Logo de la barre d'accueil : retour à l'accueil depuis n'importe quel
  // onglet, en refermant l'album éventuellement ouvert.
  void _revenirAccueil() {
    _afficherOnglet(0);
    _revenirALaRacine(0);
  }

  void _surOnglet(int index) {
    if (index == _currentIndex) {
      _revenirALaRacine(index);
    } else {
      _afficherOnglet(index);
    }
  }

  // La barre d'accueil est portée par la page racine de chaque onglet, et
  // non par le Scaffold global : un album s'ouvre ainsi dans l'onglet, avec
  // sa propre barre de retour, en gardant la nav basse.
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
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: MyAppBarAccueil(
              onLogoTap: _revenirAccueil,
              onMesFavoris: () => _afficherOnglet(1),
            ),
            body: child,
          ),
        );
      },
    );
  }

  // Un onglet jamais ouvert reste vide ; une fois ouvert, il est conservé.
  Widget _onglet(int index, Widget child) {
    return _ongletsVisites.contains(index)
        ? _buildNavigator(index, child)
        : const SizedBox.shrink();
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
        body: IndexedStack(
          index: _currentIndex,
          children: [
            // Onglet 0 — Albums
            _onglet(0, const MyList()),
            // Onglet 1 — Mes Favoris
            _onglet(1, const FavorisScreen()),
            // Onglet 2 — Club
            _onglet(2, const ClubScreen()),
          ],
        ),
        bottomNavigationBar: SpiBottomNav(
          currentIndex: _currentIndex,
          onTap: _surOnglet,
        ),
      ),
    );
  }
}
