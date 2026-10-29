import 'package:flutter/material.dart';
import 'package:spiphoto_app/spi_colors.dart';
import 'package:spiphoto_app/service/agenda_service.dart';

/// Bandeau « Prochain rendez-vous » en tête du Club : titre, date en
/// français et lieu de l'événement.
class ClubEventBanner extends StatelessWidget {
  final ClubEvent event;

  const ClubEventBanner({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.spi.surface,
        border: Border.all(color: SpiColors.olive.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
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
        ],
      ),
    );
  }
}

const List<String> _jours = [
  'lundi',
  'mardi',
  'mercredi',
  'jeudi',
  'vendredi',
  'samedi',
  'dimanche',
];

const List<String> _mois = [
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

/// « jeudi 5 novembre · 18 h 30 », « samedi 1er novembre · 9 h », date
/// seule pour une journée entière ; l'année n'apparaît que si elle diffère
/// de l'année en cours. Écrit à la main : pas de dépendance intl.
String dateEvenement(ClubEvent event, {DateTime? maintenant}) {
  final DateTime d = event.start;
  final String jour = d.day == 1 ? '1er' : '${d.day}';
  final String annee =
      d.year == (maintenant ?? DateTime.now()).year ? '' : ' ${d.year}';
  final String date =
      '${_jours[d.weekday - 1]} $jour ${_mois[d.month - 1]}$annee';
  if (event.allDay) return date;
  final String minutes =
      d.minute == 0 ? '' : ' ${d.minute.toString().padLeft(2, '0')}';
  return '$date · ${d.hour} h$minutes';
}
