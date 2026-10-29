import 'package:spiphoto_app/service/agenda_service.dart';

// Dates de l'agenda en français, écrites à la main : pas de dépendance intl.

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

/// « SAM ».
String jourCourt(DateTime d) =>
    _jours[d.weekday - 1].substring(0, 3).toUpperCase();

/// « novembre 2026 ».
String moisAnnee(DateTime d) => '${_mois[d.month - 1]} ${d.year}';

/// « 9 h », « 18 h 30 ».
String heure(DateTime d) => d.minute == 0
    ? '${d.hour} h'
    : '${d.hour} h ${d.minute.toString().padLeft(2, '0')}';

/// « samedi 1er novembre », sans le mois avec [sansMois].
String _jourMois(DateTime d, {bool sansMois = false}) {
  final String jour = d.day == 1 ? '1er' : '${d.day}';
  return '${_jours[d.weekday - 1]} $jour${sansMois ? '' : ' ${_mois[d.month - 1]}'}';
}

/// Dernier jour d'un événement « journée entière » sur plusieurs jours (la
/// fin ICS est exclusive), null s'il tient sur une journée.
DateTime? dernierJour(ClubEvent event) {
  final DateTime? fin = event.end;
  if (!event.allDay || fin == null) return null;
  final DateTime dernier = DateTime(fin.year, fin.month, fin.day - 1);
  return dernier.isAfter(event.start) ? dernier : null;
}

/// « jeudi 5 novembre · 18 h 30 », « samedi 1er novembre · 9 h », date
/// seule pour une journée entière, « du lundi 2 au samedi 14 novembre » sur
/// plusieurs jours ; l'année n'apparaît que si elle diffère de l'année en
/// cours.
String dateEvenement(ClubEvent event, {DateTime? maintenant}) {
  final int anneeCourante = (maintenant ?? DateTime.now()).year;
  final DateTime d = event.start;
  final DateTime? dernier = dernierJour(event);
  if (dernier != null) {
    final bool memeMois = d.month == dernier.month && d.year == dernier.year;
    final String anneeDebut = d.year != dernier.year ? ' ${d.year}' : '';
    final String anneeFin =
        dernier.year == anneeCourante ? '' : ' ${dernier.year}';
    return 'du ${_jourMois(d, sansMois: memeMois)}$anneeDebut'
        ' au ${_jourMois(dernier)}$anneeFin';
  }
  final String annee = d.year == anneeCourante ? '' : ' ${d.year}';
  final String date = '${_jourMois(d)}$annee';
  return event.allDay ? date : '$date · ${heure(d)}';
}

/// Horaire sous le titre dans l'agenda (la date est déjà à gauche) :
/// « 9 h – 12 h », « Toute la journée », « Jusqu'au samedi 14 novembre ».
String horaireEvenement(ClubEvent event) {
  final DateTime? dernier = dernierJour(event);
  if (dernier != null) return 'Jusqu\'au ${_jourMois(dernier)}';
  if (event.allDay) return 'Toute la journée';
  final DateTime? fin = event.end;
  final bool memeJour = fin != null &&
      fin.year == event.start.year &&
      fin.month == event.start.month &&
      fin.day == event.start.day &&
      fin.isAfter(event.start);
  return memeJour
      ? '${heure(event.start)} – ${heure(fin)}'
      : heure(event.start);
}
