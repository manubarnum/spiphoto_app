import 'package:flutter_test/flutter_test.dart';
import 'package:spiphoto_app/service/agenda_service.dart';

void main() {
  // Extrait au format du flux Google : CRLF, lignes longues repliées,
  // fuseau Europe/Paris, UTC, journées entières et série récurrente.
  const String ics = 'BEGIN:VCALENDAR\r\n'
      'X-WR-TIMEZONE:Europe/Paris\r\n'
      'BEGIN:VEVENT\r\n'
      'DTSTART;TZID=Europe/Paris:20261003T090000\r\n'
      'DTEND;TZID=Europe/Paris:20261003T120000\r\n'
      'SUMMARY:Passé\r\n'
      'STATUS:CONFIRMED\r\n'
      'END:VEVENT\r\n'
      'BEGIN:VEVENT\r\n'
      'DTSTART;TZID=Europe/Paris:20261128T140000\r\n'
      'DTEND;TZID=Europe/Paris:20261128T170000\r\n'
      'SUMMARY:RDV Asso\r\n'
      'LOCATION:L’atelier\\, 44 Av. du Général Leclerc\\, 76220 Gournay-en-Bray\\, Fr\r\n'
      ' ance\r\n'
      'DESCRIPTION:Point sur l\'expo&lt\\;br /&gt\\;&lt\\;br /&gt\\;<a href="h\r\n'
      ' ttps://exemple.fr">Invitation</a> &amp\\; café\\nÀ samedi\r\n'
      'STATUS:CONFIRMED\r\n'
      'END:VEVENT\r\n'
      'BEGIN:VEVENT\r\n'
      'DTSTART:20261105T173000Z\r\n'
      'DTEND:20261105T193000Z\r\n'
      'SUMMARY:Soirée projection\\; débat\\nau club\r\n'
      'STATUS:CONFIRMED\r\n'
      'END:VEVENT\r\n'
      'BEGIN:VEVENT\r\n'
      'DTSTART;VALUE=DATE:20261205\r\n'
      'DTEND;VALUE=DATE:20261206\r\n'
      'SUMMARY:TELETHON 2026\r\n'
      'STATUS:CONFIRMED\r\n'
      'END:VEVENT\r\n'
      // Un samedi sur deux à 9 h, du 17 octobre (heure d'été) au
      // 19 décembre ; le 28 novembre est retiré, le 12 décembre déplacé.
      'BEGIN:VEVENT\r\n'
      'DTSTART;TZID=Europe/Paris:20261017T090000\r\n'
      'DTEND;TZID=Europe/Paris:20261017T120000\r\n'
      'RRULE:FREQ=WEEKLY;WKST=SU;UNTIL=20261219T225959Z;INTERVAL=2;BYDAY=SA\r\n'
      'EXDATE;TZID=Europe/Paris:20261128T090000\r\n'
      'UID:serie@google.com\r\n'
      'SUMMARY:Rencontres du Club\r\n'
      'STATUS:CONFIRMED\r\n'
      'END:VEVENT\r\n'
      'BEGIN:VEVENT\r\n'
      'DTSTART;TZID=Europe/Paris:20261213T140000\r\n'
      'DTEND;TZID=Europe/Paris:20261213T170000\r\n'
      'RECURRENCE-ID;TZID=Europe/Paris:20261212T090000\r\n'
      'UID:serie@google.com\r\n'
      'SUMMARY:Rencontres du Club (déplacée)\r\n'
      'STATUS:CONFIRMED\r\n'
      'END:VEVENT\r\n'
      'BEGIN:VEVENT\r\n'
      'DTSTART;TZID=Europe/Paris:20261030T090000\r\n'
      'SUMMARY:Sortie annulée\r\n'
      'STATUS:CANCELLED\r\n'
      'END:VEVENT\r\n'
      'END:VCALENDAR\r\n';

  final List<ClubEvent> events =
      AgendaService.parseIcs(ics, jusqua: DateTime(2027, 6));
  ClubEvent nomme(String titre) => events.firstWhere((e) => e.title == titre);
  List<DateTime> debutsUtc(String titre) => [
        for (final ClubEvent e in events)
          if (e.title == titre) e.start.toUtc(),
      ];

  group('parseIcs', () {
    test('ignore les événements annulés', () {
      expect(events.where((e) => e.title == 'Sortie annulée'), isEmpty);
    });

    test('lit l\'heure de Paris, en hiver comme en été', () {
      // 28 novembre : UTC+1.
      expect(nomme('RDV Asso').start.toUtc(), DateTime.utc(2026, 11, 28, 13));
      // 3 octobre : heure d'été, UTC+2.
      expect(nomme('Passé').start.toUtc(), DateTime.utc(2026, 10, 3, 7));
    });

    test('lit les dates UTC', () {
      final ClubEvent e = nomme('Soirée projection; débat au club');
      expect(e.start.toUtc(), DateTime.utc(2026, 11, 5, 17, 30));
      expect(e.allDay, isFalse);
    });

    test('journée entière → allDay, à minuit local', () {
      final ClubEvent e = nomme('TELETHON 2026');
      expect(e.allDay, isTrue);
      expect(e.start, DateTime(2026, 12, 5));
      expect(e.end, DateTime(2026, 12, 6));
    });

    test('déplie les lignes longues et nettoie les échappements', () {
      expect(nomme('RDV Asso').location,
          'L’atelier, 44 Av. du Général Leclerc, 76220 Gournay-en-Bray, France');
      expect(nomme('TELETHON 2026').location, isNull);
    });

    test('description : HTML retiré, retours à la ligne gardés', () {
      expect(nomme('RDV Asso').description,
          'Point sur l\'expo\n\nInvitation & café\nÀ samedi');
      expect(nomme('TELETHON 2026').description, isNull);
    });

    test('journée entière sans DTEND : dure la journée', () {
      final List<ClubEvent> seul = AgendaService.parseIcs('BEGIN:VEVENT\n'
          'DTSTART;VALUE=DATE:20261102\n'
          'SUMMARY:Exposition\n'
          'END:VEVENT\n');
      expect(seul.single.end, DateTime(2026, 11, 3));
    });
  });

  group('récurrences', () {
    test(
        'un samedi sur deux, 9 h de Paris de part et d\'autre du '
        'changement d\'heure', () {
      expect(debutsUtc('Rencontres du Club'), [
        DateTime.utc(2026, 10, 17, 7), // heure d'été
        DateTime.utc(2026, 10, 31, 8), // heure d'hiver
        DateTime.utc(2026, 11, 14, 8),
        // 28 novembre : EXDATE ; 12 décembre : déplacé ; 26 décembre :
        // après UNTIL.
      ]);
    });

    test('chaque occurrence garde la durée de la série', () {
      final ClubEvent e = events.firstWhere((e) =>
          e.title == 'Rencontres du Club' &&
          e.start.toUtc() == DateTime.utc(2026, 11, 14, 8));
      expect(e.end!.difference(e.start), const Duration(hours: 3));
    });

    test('l\'occurrence déplacée remplace celle de la série', () {
      expect(debutsUtc('Rencontres du Club (déplacée)'),
          [DateTime.utc(2026, 12, 13, 13)]);
    });

    test('sans fin, la série s\'arrête à la limite demandée', () {
      final List<ClubEvent> serie = AgendaService.parseIcs(
        'BEGIN:VEVENT\n'
        'DTSTART;TZID=Europe/Paris:20261003T090000\n'
        'RRULE:FREQ=WEEKLY;BYDAY=SA\n'
        'SUMMARY:Hebdo\n'
        'END:VEVENT\n',
        jusqua: DateTime(2026, 10, 25),
      );
      expect(serie.map((e) => e.start.day), [3, 10, 17, 24]);
    });

    test('COUNT et UNTIL en date seule', () {
      List<int> jours(String regle) => AgendaService.parseIcs(
            'BEGIN:VEVENT\n'
            'DTSTART;VALUE=DATE:20250906\n'
            'RRULE:$regle\n'
            'SUMMARY:Série\n'
            'END:VEVENT\n',
            jusqua: DateTime(2026),
          ).map((e) => e.start.day).toList();

      expect(jours('FREQ=WEEKLY;COUNT=3'), [6, 13, 20]);
      // UNTIL inclus : le 20 septembre est un samedi.
      expect(jours('FREQ=WEEKLY;WKST=SA;UNTIL=20250920;INTERVAL=2;BYDAY=SA'),
          [6, 20]);
    });

    test('fréquence non gérée : rien plutôt qu\'une date fausse', () {
      expect(
        AgendaService.parseIcs(
          'BEGIN:VEVENT\n'
          'DTSTART;VALUE=DATE:20261105\n'
          'RRULE:FREQ=MONTHLY;BYDAY=1TH\n'
          'SUMMARY:Mensuel\n'
          'END:VEVENT\n',
          jusqua: DateTime(2027),
        ),
        isEmpty,
      );
    });
  });

  group('upcoming / nextEvent', () {
    test('ignore le passé et retient le plus proche', () {
      expect(AgendaService.nextEvent(events, DateTime(2026, 10, 29))?.title,
          'Rencontres du Club');
      expect(
        AgendaService.upcoming(events, DateTime(2026, 10, 29))
            .map((e) => e.start.toUtc()),
        orderedEquals([
          DateTime.utc(2026, 10, 31, 8),
          DateTime.utc(2026, 11, 5, 17, 30),
          DateTime.utc(2026, 11, 14, 8),
          DateTime.utc(2026, 11, 28, 13),
          DateTime(2026, 12, 5).toUtc(),
          DateTime.utc(2026, 12, 13, 13),
        ]),
      );
    });

    test('un événement en cours reste le prochain', () {
      final DateTime pendant = DateTime.utc(2026, 11, 5, 18).toLocal();
      expect(AgendaService.nextEvent(events, pendant)?.title,
          'Soirée projection; débat au club');
    });

    test('une journée entière reste affichée le jour même', () {
      expect(AgendaService.nextEvent(events, DateTime(2026, 12, 5, 20))?.title,
          'TELETHON 2026');
    });

    test('null quand tout est passé', () {
      expect(AgendaService.nextEvent(events, DateTime(2027)), isNull);
    });
  });

  test('un événement fermé reste masqué, pas le suivant', () {
    expect(AgendaService.estMasque(nomme('RDV Asso')), isFalse);

    AgendaService.masquer(nomme('RDV Asso'));
    expect(AgendaService.estMasque(nomme('RDV Asso')), isTrue);
    expect(AgendaService.estMasque(nomme('TELETHON 2026')), isFalse);
  });
}
