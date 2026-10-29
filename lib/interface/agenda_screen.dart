import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spiphoto_app/spi_colors.dart';
import 'package:spiphoto_app/service/agenda_service.dart';
import 'package:spiphoto_app/interface/dates_agenda.dart';

/// Agenda du Club : les rendez-vous à venir (calendrier Google du site),
/// regroupés par mois. Un tap sur un rendez-vous déplie sa description, un
/// tap sur le lieu l'ouvre dans l'application de cartes.
class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  late Future<List<ClubEvent>> _events;

  @override
  void initState() {
    super.initState();
    _events = AgendaService.fetchUpcoming();
  }

  // Recharge sans vider l'écran : FutureBuilder garde les données
  // précédentes pendant le chargement.
  Future<void> _recharger() {
    final Future<List<ClubEvent>> events = AgendaService.fetchUpcoming();
    setState(() {
      _events = events;
    });
    return events;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.spi.fond,
      appBar: AppBar(
        backgroundColor: context.spi.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: context.spi.encre,
          tooltip: 'Retour',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Agenda du Club',
          style: TextStyle(
            color: context.spi.encre,
            fontSize: 15.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
        // Filet bas identique à l'AppBar principale
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: SpiColors.olive.withValues(alpha: 0.4),
          ),
        ),
      ),
      body: FutureBuilder<List<ClubEvent>>(
        future: _events,
        builder: (context, snapshot) {
          final List<ClubEvent>? events = snapshot.data;
          return RefreshIndicator(
            color: context.spi.mauve,
            backgroundColor: context.spi.surface,
            onRefresh: _recharger,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (events == null && snapshot.hasError)
                  _message(
                    context,
                    'Impossible de charger l\'agenda.\nVérifiez votre connexion.',
                    action: TextButton(
                      onPressed: _recharger,
                      child: Text('Réessayer',
                          style: TextStyle(color: context.spi.mauve)),
                    ),
                  )
                else if (events == null)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (events.isEmpty)
                  _message(context, 'Aucun rendez-vous à venir.')
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList.list(children: _liste(events)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Rendez-vous précédés d'un intitulé à chaque changement de mois.
  List<Widget> _liste(List<ClubEvent> events) {
    final List<Widget> enfants = [];
    String? moisPrecedent;
    for (final ClubEvent event in events) {
      final String mois = moisAnnee(event.start);
      if (mois != moisPrecedent) {
        enfants.add(Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 10),
          child: Text(
            mois.toUpperCase(),
            style: TextStyle(
              color: context.spi.accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.4,
            ),
          ),
        ));
        moisPrecedent = mois;
      } else {
        enfants.add(const SizedBox(height: 10));
      }
      enfants.add(_CarteRendezVous(event: event));
    }
    return enfants;
  }

  Widget _message(BuildContext context, String texte, {Widget? action}) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy_outlined,
                  color: context.spi.encreSecondaire, size: 48),
              const SizedBox(height: 16),
              Text(
                texte,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (action != null) ...[const SizedBox(height: 12), action],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARTE D'UN RENDEZ-VOUS — date à gauche, titre, horaire, lieu, description
// ─────────────────────────────────────────────────────────────────────────────
class _CarteRendezVous extends StatefulWidget {
  final ClubEvent event;

  const _CarteRendezVous({required this.event});

  @override
  State<_CarteRendezVous> createState() => _CarteRendezVousState();
}

class _CarteRendezVousState extends State<_CarteRendezVous> {
  bool _deplie = false;

  Future<void> _ouvrirLieu(String lieu) async {
    final Uri url = Uri.https(
        'www.google.com', '/maps/search/', {'api': '1', 'query': lieu});
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir la carte')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ClubEvent event = widget.event;
    final String? description = event.description;

    return Material(
      color: context.spi.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: SpiColors.olive.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: description == null
            ? null
            : () => setState(() => _deplie = !_deplie),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Date ─────────────────────────────────────────────────
              Container(
                width: 48,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: context.spi.surfaceElevee,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      jourCourt(event.start),
                      style: TextStyle(
                        color: context.spi.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      '${event.start.day}',
                      style: TextStyle(
                        color: context.spi.encre,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // ── Titre, horaire, lieu, description ────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        color: context.spi.encre,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      horaireEvenement(event),
                      style: TextStyle(
                        color: context.spi.encreSecondaire,
                        fontSize: 12,
                      ),
                    ),
                    if (event.location != null) ...[
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _ouvrirLieu(event.location!),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Icon(Icons.place_outlined,
                                    color: context.spi.mauve, size: 14),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.location!,
                                  style: TextStyle(
                                    color: context.spi.mauve,
                                    fontSize: 11,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        maxLines: _deplie ? null : 2,
                        overflow: _deplie ? null : TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.spi.encreSecondaire,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Icon(
                        _deplie ? Icons.expand_less : Icons.expand_more,
                        color: context.spi.encreTertiaire,
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
