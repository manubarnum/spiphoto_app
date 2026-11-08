import 'package:flutter/material.dart';
import 'package:spiphoto_app/spi_colors.dart';
import 'package:spiphoto_app/interface/onglet_albums.dart';
import 'package:spiphoto_app/service/sources/modeles.dart';
import 'package:spiphoto_app/service/sources/sources_service.dart';

/// Écran « Sources de photos » : spiphoto.fr, puis les galeries des
/// adhérents à activer d'un interrupteur.
class SourcesScreen extends StatefulWidget {
  const SourcesScreen({super.key});

  @override
  State<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends State<SourcesScreen> {
  final SourcesService _service = SourcesService.instance;
  bool _chargement = false;
  bool _erreur = false;

  @override
  void initState() {
    super.initState();
    _actualiser();
  }

  /// Relit la liste des galeries sur le site ; en cas d'échec, la dernière
  /// liste reçue reste affichée.
  Future<void> _actualiser() async {
    setState(() {
      _chargement = true;
      _erreur = false;
    });
    try {
      await _service.actualiserGaleries();
    } catch (_) {
      if (mounted) setState(() => _erreur = true);
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _basculer(SourceConfig galerie, bool activer) async {
    final ScaffoldMessengerState messager = ScaffoldMessenger.of(context);
    messager.hideCurrentSnackBar();
    if (!activer) {
      await _service.desactiverGalerie(galerie);
      return;
    }
    await _service.activerGalerie(galerie);
    messager.showSnackBar(SnackBar(
      content: Text('${galerie.nom} ajouté à vos sources'),
      action: SnackBarAction(
        label: 'Afficher',
        onPressed: () => _afficher(galerie),
      ),
    ));
  }

  void _afficher(SourceConfig source) {
    _service.activer(source);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.spi.fond,
      appBar: AppBar(
        backgroundColor: context.spi.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: context.spi.encre,
          tooltip: 'Retour',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Sources de photos',
          style: TextStyle(
            color: context.spi.encre,
            fontSize: 15.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: SpiColors.olive.withValues(alpha: 0.4),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: context.spi.mauve,
        backgroundColor: context.spi.surface,
        onRefresh: _actualiser,
        child: ValueListenableBuilder<List<SourceConfig>>(
          valueListenable: _service.sources,
          builder: (context, sources, _) =>
              ValueListenableBuilder<List<SourceConfig>>(
            valueListenable: _service.galeriesAdherents,
            builder: (context, galeries, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const _Titre('Par défaut'),
                LigneSource(
                  config: SourcesService.spiphoto,
                  onTap: () => _afficher(SourcesService.spiphoto),
                  trailing: Icon(Icons.lock_outline,
                      size: 18, color: context.spi.encreTertiaire),
                ),
                const _Titre('Galeries des adhérents'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Les sites des membres du club, tels que présentés sur '
                    'spiphoto.fr. Activez une galerie pour la retrouver '
                    'dans le choix de la source des albums.',
                    style: TextStyle(
                      color: context.spi.encreSecondaire,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
                if (galeries.isEmpty)
                  _EtatListe(
                    chargement: _chargement,
                    erreur: _erreur,
                    onReessayer: _actualiser,
                  )
                else ...[
                  if (_erreur)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        'Liste non actualisée (hors ligne ?) : dernière '
                        'version reçue.',
                        style: TextStyle(
                            color: context.spi.encreTertiaire, fontSize: 11),
                      ),
                    ),
                  for (final SourceConfig g in galeries)
                    LigneSource(
                      config: g,
                      onTap: () => _basculer(g, !sources.contains(g)),
                      trailing: Switch(
                        value: sources.contains(g),
                        activeTrackColor: SpiColors.olive,
                        onChanged: (actif) => _basculer(g, actif),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Titre extends StatelessWidget {
  final String texte;

  const _Titre(this.texte);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
      child: Text(
        texte.toUpperCase(),
        style: TextStyle(
          color: context.spi.encre,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.2,
        ),
      ),
    );
  }
}

class _EtatListe extends StatelessWidget {
  final bool chargement;
  final bool erreur;
  final VoidCallback onReessayer;

  const _EtatListe({
    required this.chargement,
    required this.erreur,
    required this.onReessayer,
  });

  @override
  Widget build(BuildContext context) {
    if (chargement) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            erreur
                ? 'Impossible de charger la liste des galeries.\n'
                    'Vérifiez votre connexion.'
                : 'Aucune galerie disponible.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.spi.encreSecondaire, fontSize: 13),
          ),
          if (erreur)
            TextButton.icon(
              onPressed: onReessayer,
              icon: Icon(Icons.refresh, color: context.spi.mauve),
              label:
                  Text('Réessayer', style: TextStyle(color: context.spi.mauve)),
            ),
        ],
      ),
    );
  }
}
