import 'package:flutter/material.dart';
import 'package:spiphoto_app/spi_colors.dart';
import 'package:spiphoto_app/service/agenda_service.dart';
import 'package:spiphoto_app/interface/dates_agenda.dart';

/// Bandeau « Prochain rendez-vous » en tête du Club : titre, date en
/// français et lieu de l'événement. Un tap ouvre l'agenda du Club, la croix
/// ferme le bandeau.
class ClubEventBanner extends StatelessWidget {
  final ClubEvent event;
  final VoidCallback onOuvrir;
  final VoidCallback onFermer;

  const ClubEventBanner({
    super.key,
    required this.event,
    required this.onOuvrir,
    required this.onFermer,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.spi.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: SpiColors.olive.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOuvrir,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
          child: _contenu(context),
        ),
      ),
    );
  }

  Widget _contenu(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.spi.surfaceElevee,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.event, color: context.spi.accent, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PROCHAIN RENDEZ-VOUS',
                style: TextStyle(
                  color: context.spi.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                event.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.spi.encre,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateEvenement(event),
                style: TextStyle(
                  color: context.spi.encreSecondaire,
                  fontSize: 12,
                ),
              ),
              if (event.location != null) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(Icons.place_outlined,
                          color: context.spi.encreTertiaire, size: 14),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.spi.encreTertiaire,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: context.spi.encreTertiaire, size: 18),
          tooltip: 'Masquer ce rendez-vous',
          visualDensity: VisualDensity.compact,
          onPressed: onFermer,
        ),
      ],
    );
  }
}
