import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

/// Prochain événement du calendrier Google public de SPIPHOTO.
class ClubEvent {
  final String title;
  final DateTime start;
  final DateTime? end;
  final bool allDay;
  final String? location;

  const ClubEvent({
    required this.title,
    required this.start,
    this.end,
    this.allDay = false,
    this.location,
  });
}

class AgendaService {
  static const _icsUrl = 'https://calendar.google.com/calendar/ical/'
      'c_e646eb53b9f53a11d8431102d8c4fb2f1120fa4c8963e5c80c876f43b145d7c2'
      '%40group.calendar.google.com/public/basic.ics';

  /// Renvoie le prochain événement à venir (ou en cours), null si aucun ou
  /// en cas d'erreur réseau : le bandeau est alors simplement masqué.
  static Future<ClubEvent?> fetchNextEvent() async {
    try {
      final res = await http
          .get(Uri.parse(_icsUrl))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      // Le flux est en UTF-8 ; sans charset annoncé, http lirait du latin-1.
      return nextEvent(parseIcs(utf8.decode(res.bodyBytes)), DateTime.now());
    } catch (_) {
      return null;
    }
  }

  /// L'événement non terminé qui commence le plus tôt (un événement en
  /// cours passe donc devant les suivants).
  @visibleForTesting
  static ClubEvent? nextEvent(List<ClubEvent> events, DateTime now) {
    final aVenir = events.where((e) => (e.end ?? e.start).isAfter(now)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return aVenir.isEmpty ? null : aVenir.first;
  }

  @visibleForTesting
  static List<ClubEvent> parseIcs(String ics) {
    // Dépliage des lignes longues (RFC 5545 : continuation = espace ou tab).
    final lines = ics
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'\n[ \t]'), '')
        .split('\n');

    final events = <ClubEvent>[];
    Map<String, String>? current;

    for (final line in lines) {
      if (line == 'BEGIN:VEVENT') {
        current = {};
      } else if (line == 'END:VEVENT') {
        final e = current == null ? null : _toEvent(current);
        if (e != null) events.add(e);
        current = null;
      } else if (current != null) {
        final i = line.indexOf(':');
        if (i > 0) current[line.substring(0, i)] = line.substring(i + 1);
      }
    }
    return events;
  }

  static ClubEvent? _toEvent(Map<String, String> p) {
    // Les événements récurrents (RRULE) ne sont pas dépliés ici.
    if (p.keys.any((k) => k.startsWith('RRULE'))) return null;
    if (p['STATUS'] == 'CANCELLED') return null;

    final startKey = p.keys.firstWhere(
      (k) => k.startsWith('DTSTART'),
      orElse: () => '',
    );
    if (startKey.isEmpty) return null;
    final endKey = p.keys.firstWhere(
      (k) => k.startsWith('DTEND'),
      orElse: () => '',
    );

    final start = _date(startKey, p[startKey]!);
    if (start == null) return null;
    final allDay = p[startKey]!.trim().length == 8;

    return ClubEvent(
      title: _text(p['SUMMARY'] ?? 'Événement'),
      start: start,
      // Journée entière sans fin : elle dure la journée (RFC 5545).
      end: endKey.isNotEmpty
          ? _date(endKey, p[endKey]!)
          : (allDay ? DateTime(start.year, start.month, start.day + 1) : null),
      allDay: allDay,
      location: p['LOCATION'] == null || p['LOCATION']!.isEmpty
          ? null
          : _text(p['LOCATION']!),
    );
  }

  /// 20261105 (journée), 20261105T183000Z (UTC), 20261105T183000 avec
  /// TZID=Europe/Paris, ou sans fuseau (heure locale du téléphone).
  static DateTime? _date(String key, String v) {
    final m = RegExp(r'^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z)?)?$')
        .firstMatch(v.trim());
    if (m == null) return null;
    final d = [
      for (var i = 1; i <= 6; i++) int.tryParse(m.group(i) ?? '') ?? 0
    ];
    if (m.group(7) == 'Z') {
      return DateTime.utc(d[0], d[1], d[2], d[3], d[4], d[5]).toLocal();
    }
    final tzid = RegExp(r'TZID="?([^;:"]+)').firstMatch(key)?.group(1);
    if (m.group(4) != null && tzid == 'Europe/Paris') {
      return _parisVersUtc(DateTime.utc(d[0], d[1], d[2], d[3], d[4], d[5]))
          .toLocal();
    }
    return DateTime(d[0], d[1], d[2], d[3], d[4], d[5]);
  }

  /// Heure de Paris (portée par un DateTime UTC) → instant UTC. Heure d'été
  /// de l'UE : du dernier dimanche de mars au dernier dimanche d'octobre,
  /// à 1 h UTC. Évite une dépendance de fuseaux pour le seul fuseau du flux.
  static DateTime _parisVersUtc(DateTime heureParis) {
    final y = heureParis.year;
    final ete = heureParis.subtract(const Duration(hours: 2));
    if (!ete.isBefore(_dernierDimancheUtc(y, 3)) &&
        ete.isBefore(_dernierDimancheUtc(y, 10))) {
      return ete;
    }
    return heureParis.subtract(const Duration(hours: 1));
  }

  static DateTime _dernierDimancheUtc(int annee, int mois) {
    final dernier = DateTime.utc(annee, mois + 1, 0, 1);
    return dernier.subtract(Duration(days: dernier.weekday % 7));
  }

  static String _text(String v) => v
      .replaceAllMapped(
        RegExp(r'\\([\\,;nN])'),
        (m) => switch (m[1]) { 'n' || 'N' => ' ', final c => c! },
      )
      .trim();
}
