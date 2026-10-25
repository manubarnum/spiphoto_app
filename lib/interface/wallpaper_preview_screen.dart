import 'dart:async';
import 'dart:math' as math;

import 'package:extended_image/extended_image.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:spiphoto_app/spi_colors.dart';
import 'package:spiphoto_app/service/wallpaper_service.dart';

/// Écran(s) sur le(s)quel(s) poser le fond d'écran. [code] est la valeur
/// attendue par le canal natif (voir MainActivity.kt).
enum CibleFondEcran {
  accueil(1, 'Accueil', 'Appliquer à l\'accueil'),
  verrouillage(2, 'Verrouillage', 'Appliquer au verrouillage'),
  lesDeux(3, 'Les deux', 'Appliquer aux deux écrans');

  const CibleFondEcran(this.code, this.libelle, this.libelleBouton);

  final int code;
  final String libelle;
  final String libelleBouton;
}

// ─────────────────────────────────────────────────────────────────────────────
// APERÇU AVANT POSE — cible, recadrage, confirmation
// ─────────────────────────────────────────────────────────────────────────────
class WallpaperPreviewScreen extends StatefulWidget {
  final String imageUrl;

  const WallpaperPreviewScreen({super.key, required this.imageUrl});

  @override
  State<WallpaperPreviewScreen> createState() => _WallpaperPreviewScreenState();
}

class _WallpaperPreviewScreenState extends State<WallpaperPreviewScreen> {
  final WallpaperService _service = WallpaperService();

  // Même fournisseur que la visionneuse : l'image est déjà en cache.
  late final ImageProvider _image =
      ExtendedNetworkImageProvider(widget.imageUrl, cache: true);
  ImageStream? _flux;
  ImageStreamListener? _ecouteur;
  Size? _tailleImage;
  bool _erreurImage = false;

  CibleFondEcran _cible = CibleFondEcran.lesDeux;

  // Recadrage : la réglette règle le zoom (0 = la photo couvre juste
  // l'écran, 1 = zoom ×2), le glisser dans l'aperçu déplace la zone.
  // Le centre est exprimé en fractions de l'image, indépendant du zoom.
  double _cropScale = 0.62;
  Offset _centre = const Offset(0.5, 0.5);
  static const double _zoomMax = 2.0;

  // Taille intérieure de la maquette, connue après la mise en page.
  Size? _cadre;

  // « Les deux » : l'aperçu alterne entre les surcouches.
  bool _surcoucheVerrouillage = true;
  Timer? _alternance;

  bool _application = false;

  @override
  void initState() {
    super.initState();
    _demarrerAlternance();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_flux != null) return;
    _flux = _image.resolve(createLocalImageConfiguration(context));
    _ecouteur = ImageStreamListener(
      (info, _) {
        final Size taille =
            Size(info.image.width.toDouble(), info.image.height.toDouble());
        info.dispose();
        if (mounted) setState(() => _tailleImage = taille);
      },
      onError: (_, __) {
        if (mounted) setState(() => _erreurImage = true);
      },
    );
    _flux!.addListener(_ecouteur!);
  }

  @override
  void dispose() {
    _flux?.removeListener(_ecouteur!);
    _alternance?.cancel();
    super.dispose();
  }

  void _demarrerAlternance() {
    _alternance?.cancel();
    _alternance = null;
    if (_cible != CibleFondEcran.lesDeux) return;
    _alternance = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (mounted) {
        setState(() => _surcoucheVerrouillage = !_surcoucheVerrouillage);
      }
    });
  }

  void _choisirCible(CibleFondEcran cible) {
    setState(() {
      _cible = cible;
      _surcoucheVerrouillage = cible != CibleFondEcran.accueil;
    });
    _demarrerAlternance();
  }

  double get _zoom => 1 + _cropScale * (_zoomMax - 1);

  /// Zone visible dans le [cadre], en fractions de l'image.
  Rect _zone(Size cadre, Size image) {
    final double echelle =
        math.max(cadre.width / image.width, cadre.height / image.height) *
            _zoom;
    final double largeur = math.min(1.0, cadre.width / echelle / image.width);
    final double hauteur = math.min(1.0, cadre.height / echelle / image.height);
    return Rect.fromCenter(
      center: Offset(
        _centre.dx.clamp(largeur / 2, 1 - largeur / 2),
        _centre.dy.clamp(hauteur / 2, 1 - hauteur / 2),
      ),
      width: largeur,
      height: hauteur,
    );
  }

  void _deplacer(DragUpdateDetails details) {
    final Size? cadre = _cadre;
    final Size? image = _tailleImage;
    if (cadre == null || image == null) return;
    final Rect zone = _zone(cadre, image);
    // Glisser vers la droite fait apparaître la partie gauche de la photo.
    setState(() {
      _centre = Offset(
        _centre.dx - details.delta.dx / cadre.width * zone.width,
        _centre.dy - details.delta.dy / cadre.height * zone.height,
      );
      _centre = _zone(cadre, image).center;
    });
  }

  Future<void> _appliquer() async {
    final Size? cadre = _cadre;
    final Size? image = _tailleImage;
    if (cadre == null || image == null || _application) return;

    setState(() => _application = true);
    try {
      await _service.setWallpaper(widget.imageUrl, _cible.code,
          crop: _zone(cadre, image));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: SpiColors.succes, size: 20),
              SizedBox(width: 10),
              Text('Fond d\'écran appliqué'),
            ],
          ),
        ),
      );
      Navigator.pop(context);
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _application = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Impossible d\'appliquer le fond d\'écran : ${e.message}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size ecran = MediaQuery.sizeOf(context);

    // Écran toujours sombre (centré sur la photo), quel que soit le thème :
    // icônes claires dans la barre d'état.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: SpiColors.noir,
        body: SafeArea(
          child: Column(
            children: [
              // ── Entête ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: SpiColors.texte, size: 20),
                      tooltip: 'Fermer',
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 2),
                    const Text(
                      'APERÇU',
                      style: TextStyle(
                        color: SpiColors.texte,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Maquette de téléphone ──────────────────────────────────
              // Aux proportions de l'écran réel : ce qui est vu est ce qui
              // sera posé. Occupe toute la hauteur libre (la maquette du
              // handoff, plafonnée à 430 × 212 px, était jugée trop petite),
              // largeur limitée à 70 % de l'écran.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                  child: LayoutBuilder(
                    builder: (context, contraintes) {
                      final double ratio = ecran.width / ecran.height;
                      double hauteur = contraintes.maxHeight;
                      double largeur = hauteur * ratio;
                      if (largeur > ecran.width * 0.7) {
                        largeur = ecran.width * 0.7;
                        hauteur = largeur / ratio;
                      }
                      return Center(
                        child: Container(
                          width: largeur,
                          height: hauteur,
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: SpiColors.olive, width: 2),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: _contenuMaquette(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ── Réglages et validation ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SelecteurCible(cible: _cible, onChanged: _choisirCible),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 32,
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2,
                                activeTrackColor: SpiColors.olive,
                                inactiveTrackColor: SpiColors.surfaceHigh,
                                thumbColor: SpiColors.mauveClair,
                                overlayColor: SpiColors.mauveClair
                                    .withValues(alpha: 0.15),
                                trackShape: const RectangularSliderTrackShape(),
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8,
                                  elevation: 0,
                                  pressedElevation: 0,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 16),
                                showValueIndicator: ShowValueIndicator.never,
                              ),
                              child: Slider(
                                value: _cropScale,
                                padding: EdgeInsets.zero,
                                semanticFormatterCallback: (valeur) =>
                                    'Zoom ${(1 + valeur * (_zoomMax - 1)).toStringAsFixed(1)}×',
                                onChanged: (valeur) =>
                                    setState(() => _cropScale = valeur),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.zoom_out_map,
                            color: SpiColors.texteMuted, size: 20),
                      ],
                    ),
                    const Text(
                      'Recadrage — glissez pour ajuster',
                      style: TextStyle(
                        color: SpiColors.texteMuted,
                        fontSize: 11,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _BoutonAppliquer(
                      libelle: _cible.libelleBouton,
                      enCours: _application,
                      onTap: _tailleImage == null ? null : _appliquer,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contenuMaquette() {
    final Size? image = _tailleImage;

    if (_erreurImage) {
      return const ColoredBox(
        color: SpiColors.surfaceAlt,
        child: Center(
          child: Icon(Icons.broken_image_outlined,
              color: SpiColors.texteMuted, size: 32),
        ),
      );
    }
    if (image == null) {
      return const ColoredBox(
        color: SpiColors.surface,
        child: Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: SpiColors.mauve),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, contraintes) {
        final Size cadre = contraintes.biggest;
        _cadre = cadre;
        final Rect zone = _zone(cadre, image);
        final double echelle = cadre.width / (zone.width * image.width);

        return GestureDetector(
          onPanUpdate: _deplacer,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // ── Photo recadrée ─────────────────────────────────────
              Positioned(
                left: -zone.left * image.width * echelle,
                top: -zone.top * image.height * echelle,
                width: image.width * echelle,
                height: image.height * echelle,
                child: Image(
                  image: _image,
                  fit: BoxFit.fill,
                  gaplessPlayback: true,
                ),
              ),

              // ── Léger voile haut ───────────────────────────────────
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.4],
                        colors: [
                          SpiColors.noir.withValues(alpha: 0.3),
                          SpiColors.noir.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Fausse barre d'état ────────────────────────────────
              Positioned(
                top: 12,
                left: 14,
                right: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _heure(DateTime.now()),
                      style: TextStyle(
                        color: SpiColors.texte.withValues(alpha: 0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(Icons.battery_full,
                        color: SpiColors.texte.withValues(alpha: 0.9),
                        size: 12),
                  ],
                ),
              ),

              // ── Surcouche selon la cible ───────────────────────────
              if (_surcoucheVerrouillage)
                ..._surcoucheVerrouillageWidgets()
              else
                ..._surcoucheAccueilWidgets(),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _surcoucheVerrouillageWidgets() {
    final DateTime maintenant = DateTime.now();
    const List<Shadow> ombre = [
      Shadow(color: Color(0x99000000), blurRadius: 10, offset: Offset(0, 2)),
    ];
    return [
      Positioned(
        top: 62,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Column(
            children: [
              Text(
                _heure(maintenant),
                style: const TextStyle(
                  color: SpiColors.texte,
                  fontSize: 44,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -1,
                  shadows: ombre,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _date(maintenant),
                style: TextStyle(
                  color: SpiColors.texte.withValues(alpha: 0.85),
                  fontSize: 12,
                  letterSpacing: 1,
                  shadows: ombre,
                ),
              ),
            ],
          ),
        ),
      ),
      // Indice de déverrouillage
      Positioned(
        bottom: 16,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Icon(Icons.lock_outline,
              color: SpiColors.texte.withValues(alpha: 0.8), size: 14),
        ),
      ),
    ];
  }

  List<Widget> _surcoucheAccueilWidgets() {
    Widget icone() => AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: SpiColors.texte.withValues(alpha: 0.22),
              border:
                  Border.all(color: SpiColors.texte.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(11),
            ),
          ),
        );
    Widget rangee(double ecart) => Row(
          children: [
            for (int i = 0; i < 4; i++) ...[
              if (i > 0) SizedBox(width: ecart),
              Expanded(child: icone()),
            ],
          ],
        );

    return [
      // Grille d'applications
      Positioned(
        top: 58,
        left: 22,
        right: 22,
        child: IgnorePointer(
          child: Column(
            children: [rangee(14), const SizedBox(height: 14), rangee(14)],
          ),
        ),
      ),
      // Dock
      Positioned(
        bottom: 14,
        left: 14,
        right: 14,
        child: IgnorePointer(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SpiColors.texte.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: rangee(10),
          ),
        ),
      ),
    ];
  }

  static String _heure(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static const List<String> _jours = [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche',
  ];
  static const List<String> _mois = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  static String _date(DateTime t) =>
      '${_jours[t.weekday - 1]} ${t.day} ${_mois[t.month - 1]}';
}

// ─────────────────────────────────────────────────────────────────────────────
// SÉLECTEUR DE CIBLE — segmenté 3 positions
// ─────────────────────────────────────────────────────────────────────────────
class _SelecteurCible extends StatelessWidget {
  final CibleFondEcran cible;
  final ValueChanged<CibleFondEcran> onChanged;

  const _SelecteurCible({required this.cible, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SpiColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final CibleFondEcran option in CibleFondEcran.values) ...[
            if (option.index > 0) const SizedBox(width: 4),
            Expanded(
              child: Semantics(
                selected: option == cible,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(option),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: option == cible
                          ? SpiColors.olive
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      option.libelle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: option == cible
                            ? SpiColors.texte
                            : SpiColors.texteMuted,
                        fontSize: 12,
                        fontWeight:
                            option == cible ? FontWeight.w700 : FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOUTON DE VALIDATION — pilule pleine largeur
// ─────────────────────────────────────────────────────────────────────────────
class _BoutonAppliquer extends StatelessWidget {
  final String libelle;
  final bool enCours;
  final VoidCallback? onTap;

  const _BoutonAppliquer({
    required this.libelle,
    required this.enCours,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null
          ? SpiColors.olive.withValues(alpha: 0.5)
          : SpiColors.olive,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enCours ? null : onTap,
        highlightColor: SpiColors.oliveClair, // état pressé
        child: SizedBox(
          height: 54,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (enCours)
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: SpiColors.texte),
                )
              else
                const Icon(Icons.wallpaper, color: SpiColors.texte, size: 22),
              const SizedBox(width: 10),
              Text(
                libelle,
                style: const TextStyle(
                  color: SpiColors.texte,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
