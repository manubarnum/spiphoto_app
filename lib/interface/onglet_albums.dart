import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:spiphoto_app/spi_colors.dart';
import 'package:spiphoto_app/interface/album_list.dart';
import 'package:spiphoto_app/interface/sources_screen.dart';
import 'package:spiphoto_app/service/sources/modeles.dart';
import 'package:spiphoto_app/service/sources/source_photos.dart';
import 'package:spiphoto_app/service/sources/sources_service.dart';

/// Onglet Albums : bandeau de la source affichée (et de ses catégories),
/// puis la mosaïque de ses albums.
class OngletAlbums extends StatefulWidget {
  const OngletAlbums({super.key});

  @override
  State<OngletAlbums> createState() => _OngletAlbumsState();
}

class _OngletAlbumsState extends State<OngletAlbums> {
  final SourcesService _service = SourcesService.instance;

  // Catégories de chaque source, lues une fois par lancement.
  final Map<SourceConfig, Future<List<Categorie>>> _categories = {};
  Categorie? _categorie;

  Future<List<Categorie>> _categoriesDe(SourceConfig config) =>
      _categories.putIfAbsent(
          config,
          () => _service
              .sourcePour(config)
              .categories()
              .catchError((_) => const <Categorie>[]));

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SourceConfig>(
      valueListenable: _service.sourceActive,
      builder: (context, config, _) {
        final SourcePhotos source = _service.sourcePour(config);
        // Catégorie d'une autre source : oubliée.
        return FutureBuilder<List<Categorie>>(
          future: _categoriesDe(config),
          builder: (context, snapshot) {
            final List<Categorie> categories = snapshot.data ?? const [];
            final Categorie? categorie =
                categories.any((c) => c.id == _categorie?.id)
                    ? _categorie
                    : null;
            return Column(
              children: [
                _BandeauSource(
                  config: config,
                  categories: categories,
                  categorie: categorie,
                  onCategorie: (c) => setState(() => _categorie = c),
                ),
                Expanded(
                  child: MyList(
                    key: ValueKey('${config.type.name}|${config.adresse}'
                        '|${categorie?.id}'),
                    source: source,
                    categorieId: categorie?.id,
                    titreSection: categorie?.nom ?? 'Tous les albums',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BANDEAU — source affichée (menu) et puces de catégories
// ─────────────────────────────────────────────────────────────────────────────
class _BandeauSource extends StatelessWidget {
  final SourceConfig config;
  final List<Categorie> categories;
  final Categorie? categorie;
  final ValueChanged<Categorie?> onCategorie;

  const _BandeauSource({
    required this.config,
    required this.categories,
    required this.categorie,
    required this.onCategorie,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.spi.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _choisirSource(context),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                    child: Row(
                      children: [
                        Icon(Icons.photo_library_outlined,
                            size: 18, color: context.spi.accent),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            config.nom,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.spi.encre,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down,
                            color: context.spi.encreSecondaire),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.tune,
                    size: 20, color: context.spi.encreSecondaire),
                tooltip: 'Gérer les sources',
                onPressed: () => ouvrirSources(context),
              ),
              const SizedBox(width: 4),
            ],
          ),
          if (categories.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                children: [
                  _Puce(
                    libelle: 'Tout',
                    choisie: categorie == null,
                    onTap: () => onCategorie(null),
                  ),
                  for (final Categorie c in categories)
                    _Puce(
                      libelle: c.nom,
                      choisie: categorie?.id == c.id,
                      onTap: () => onCategorie(c),
                    ),
                ],
              ),
            ),
          Container(height: 1, color: SpiColors.olive.withValues(alpha: 0.4)),
        ],
      ),
    );
  }

  Future<void> _choisirSource(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      // Le panneau se ferme avant d'ouvrir l'écran Sources dans l'onglet.
      builder: (_) => _ChoixSource(onGerer: () => ouvrirSources(context)),
    );
  }
}

/// Ouvre l'écran Sources dans le navigateur de l'onglet (nav basse gardée).
void ouvrirSources(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const SourcesScreen()),
  );
}

class _Puce extends StatelessWidget {
  final String libelle;
  final bool choisie;
  final VoidCallback onTap;

  const _Puce(
      {required this.libelle, required this.choisie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: choisie ? SpiColors.olive : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: SpiColors.olive.withValues(alpha: choisie ? 1 : 0.5),
            ),
          ),
          child: Text(
            libelle,
            style: TextStyle(
              color: choisie ? SpiColors.texte : context.spi.encre,
              fontSize: 12,
              fontWeight: choisie ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PANNEAU — choix de la source parmi celles de l'utilisateur
// ─────────────────────────────────────────────────────────────────────────────
class _ChoixSource extends StatelessWidget {
  final VoidCallback onGerer;

  const _ChoixSource({required this.onGerer});

  @override
  Widget build(BuildContext context) {
    final SourcesService service = SourcesService.instance;
    return SafeArea(
      top: false,
      child: ValueListenableBuilder<List<SourceConfig>>(
        valueListenable: service.sources,
        builder: (context, sources, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'SOURCE DES ALBUMS',
                style: TextStyle(
                  color: context.spi.encreSecondaire,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final SourceConfig s in sources)
                    LigneSource(
                      config: s,
                      choisie: s == service.sourceActive.value,
                      onTap: () {
                        service.activer(s);
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: context.spi.surfaceElevee,
            ),
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                onGerer();
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  children: [
                    Icon(Icons.tune, color: context.spi.mauve, size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        sources.length > 1
                            ? 'Gérer les sources'
                            : 'Ajouter les galeries des adhérents',
                        style: TextStyle(
                          color: context.spi.mauve,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Une source : vignette, nom, nature ; coche ou [trailing] à droite.
class LigneSource extends StatelessWidget {
  final SourceConfig config;
  final bool choisie;
  final VoidCallback? onTap;
  final Widget? trailing;

  const LigneSource({
    super.key,
    required this.config,
    this.choisie = false,
    this.onTap,
    this.trailing,
  });

  static String nature(SourceConfig config) => switch (config.type) {
        TypeSource.spiphoto => 'Albums du club · favoris',
        TypeSource.piwigo => 'Galerie Piwigo · ${config.adresse.host}',
        TypeSource.lychee => 'Galerie Lychee · ${config.adresse.host}',
        TypeSource.wordpress => 'Site WordPress · ${config.adresse.host}',
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _Vignette(config: config),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.spi.encre,
                      fontSize: 14,
                      fontWeight: choisie ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nature(config),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.spi.encreSecondaire,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (choisie)
              Icon(Icons.check, color: context.spi.accent, size: 22),
          ],
        ),
      ),
    );
  }
}

/// Vignette 3:2 de la source : logo du club, ou photo de la pellicule du
/// site pour une galerie d'adhérent.
class _Vignette extends StatelessWidget {
  final SourceConfig config;

  const _Vignette({required this.config});

  @override
  Widget build(BuildContext context) {
    final String? image = config.image;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 54,
        height: 36,
        color: context.spi.surfaceAlt,
        child: config.type == TypeSource.spiphoto
            ? Padding(
                padding: const EdgeInsets.all(5),
                child: Image.asset('assets/icons/mon_logo1.png'),
              )
            : image == null
                ? Icon(Icons.photo_outlined,
                    size: 18, color: context.spi.encreSecondaire)
                : ExtendedImage.network(
                    image,
                    fit: BoxFit.cover,
                    cacheWidth: 162,
                    loadStateChanged: (etat) =>
                        etat.extendedImageLoadState == LoadState.failed
                            ? Icon(Icons.photo_outlined,
                                size: 18, color: context.spi.encreSecondaire)
                            : null,
                  ),
      ),
    );
  }
}
