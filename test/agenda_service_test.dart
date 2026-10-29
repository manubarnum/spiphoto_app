import 'package:flutter_test/flutter_test.dart';
import 'package:spiphoto_app/service/agenda_service.dart';

void main() {
  // Extrait au format du flux Google : CRLF, lignes longues repliées,
  // fuseau Europe/Paris, UTC et journées entières.
  const String ics = 'BEGIN:VCALENDAR\r\n'
      'X-WR-TIMEZONE:Europe/Paris\r\n'
      'BEGIN:VEVENT\r\n'
      'DTSTART;TZID=Europe/Paris:20261003T090000\r\n'
      'DTEND;TZID=Europe/Paris:20261003T120000\r\n'
      'SUMMARY:Passé\r\n'
      'STATUS:CONFIRMED\r\n'
      'END:VEVENT\r\n'
      'BEGIN:VEVENT\r\n'
      'DTSTART;TZID=Europe/Paris:20261128T090000\r\n'
      'DTEND;TZID=Europe/Paris:20261128T120000\r\n'
      'SUMMARY:RDV Asso\r\n'
      'LOCATION:L’atelier\\, 44 Av. du Général Leclerc\\, 76220 Gournay-en-Bray\\, Fr\r\n'
      ' ance\r\n'
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
      'BEGIN:VEVENT\r\n'
      'DTSTART;TZID=Europe/Paris:20261031T090000\r\n'
      'RRULE:FREQ=WEEKLY;INTERVAL=2;BYDAY=SA\r\n'
      'SUMMARY:Rencontres du Club\r\n'
      'STATUS:CONFIRMED\r\n'
      'END:VEVENT\r\n'
      'BEGIN:VEVENT\r\n'
      'DTSTART;TZID=Europe/Paris:20261030T090000\r\n'
      'SUMMARY:Sortie annulée\r\n'
      'STATUS:CANCELLED\r\n'
      'END:VEVENT\r\n'
      'END:VCALENDAR\r\n';

  final List<ClubEvent> events = AgendaService.parseIcs(ics);
  ClubEvent nomme(String titre) => events.firstWhere((e) => e.title == titre);

  group('parseIcs', () {
    test('ignore les événements récurrents et annulés', () {
      expect(events.map((e) => e.title), [
        'Passé',
        'RDV Asso',
        'Soirée projection; débat au club',
        'TELETHON 2026',
      ]);
    });

    test('lit l\'heure de Paris, en hiver comme en été', () {
      // 28 novembre : UTC+1.
      expect(nomme('RDV Asso').start.toUtc(), DateTime.utc(2026, 11, 28, 8));
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

    test('journée entière sans DTEND : dure la journée', () {
      final List<ClubEvent> seul = AgendaService.parseIcs('BEGIN:VEVENT\n'
          'DTSTART;VALUE=DATE:20261102\n'
          'SUMMARY:Exposition\n'
          'END:VEVENT\n');
      expect(seul.single.end, DateTime(2026, 11, 3));
    });
  });

  group('nextEvent', () {
    test('ignore le passé et retient le plus proche', () {
      expect(AgendaService.nextEvent(events, DateTime(2026, 10, 29))?.title,
          'Soirée projection; débat au club');
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
}
