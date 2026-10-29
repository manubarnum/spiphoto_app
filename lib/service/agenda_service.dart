import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

/// Événement du calendrier Google public de SPIPHOTO.
class ClubEvent {
  final String title;
  final DateTime start;
  final DateTime? end;
  final bool allDay;
  final String? location;

  /// Texte brut : le HTML du calendrier Google est retiré.
  final String? description;

  const ClubEvent({
    required this.title,
    required this.start,
    this.end,
    this.allDay = false,
    this.location,
    this.description,
  });
}

class AgendaService {
  static const _icsUrl = 'https://calendar.google.com/calendar/ical/'
      'c_e646eb53b9f53a11d8431102d8c4fb2f1120fa4c8963e5c80c876f43b145d7c2'
      '%40group.calendar.google.com/public/basic.ics';

  // Dernier événement fermé par l'utilisateur, en mémoire seulement : le
  // bandeau revient au prochain lancement de l'app.
  static String? _masque;

  static String _id(ClubEvent e) =>
      '${e.start.toUtc().toIso8601String()}|${e.title}';

  /// Le bandeau fermé reste masqué pour cet événement jusqu'à la fin de la
  /// session ; le suivant s'affichera normalement.
  static void masquer(ClubEvent event) => _masque = _id(event);

  static bool estMasque(ClubEvent event) => _masque == _id(event);

  /// Événements à venir ou en cours, du plus proche au plus lointain, sur
  /// un an. Lève une exception en cas d'erreur réseau (écran Agenda).
  static Future<List<ClubEvent>> fetchUpcoming() async {
    final res =
        await http.get(Uri.parse(_icsUrl)).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw http.ClientException('HTTP ${res.statusCode}', Uri.parse(_icsUrl));
    }
    final now = DateTime.now();
    // Le flux est en UTF-8 ; sans charset annoncé, http lirait du latin-1.
    return upcoming(
      parseIcs(utf8.decode(res.bodyBytes),
          jusqua: now.add(const Duration(days: 366))),
      now,
    );
  }

  /// Renvoie le prochain événement à venir (ou en cours), null si aucun ou
  /// en cas d'erreur réseau : le bandeau est alors simplement masqué.
  static Future<ClubEvent?> fetchNextEvent() async {
    try {
      final events = await fetchUpcoming();
      return events.isEmpty ? null : events.first;
    } catch (_) {
      return null;
    }
  }

  /// Les événements non terminés, par début croissant (un événement en
  /// cours passe donc devant les suivants).
  @visibleForTesting
  static List<ClubEvent> upcoming(List<ClubEvent> events, DateTime now) =>
      events.where((e) => (e.end ?? e.start).isAfter(now)).toList()
        ..sort((a, b) => a.start.compareTo(b.start));

  @visibleForTesting
  static ClubEvent? nextEvent(List<ClubEvent> events, DateTime now) {
    final aVenir = upcoming(events, now);
    return aVenir.isEmpty ? null : aVenir.first;
  }

  /// Événements du flux, récurrences dépliées jusqu'à [jusqua] (un an par
  /// défaut) : les dates exclues (EXDATE) sont retirées, les occurrences
  /// modifiées (RECURRENCE-ID) remplacent celles de la série.
  @visibleForTesting
  static List<ClubEvent> parseIcs(String ics, {DateTime? jusqua}) {
    final limite = jusqua ?? DateTime.now().add(const Duration(days: 366));

    // Dépliage des lignes longues (RFC 5545 : continuation = espace ou tab).
    final lines = ics
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'\n[ \t]'), '')
        .split('\n');

    final bruts = <Map<String, String>>[];
    Map<String, String>? current;

    for (final line in lines) {
      if (line == 'BEGIN:VEVENT') {
        current = {};
      } else if (line == 'END:VEVENT') {
        if (current != null) bruts.add(current);
        current = null;
      } else if (current != null) {
        final i = line.indexOf(':');
        if (i <= 0) continue;
        final cle = line.substring(0, i);
        final valeur = line.substring(i + 1);
        // Propriété répétée (EXDATE) : valeurs mises bout à bout.
        current[cle] =
            current[cle] == null ? valeur : '${current[cle]},$valeur';
      }
    }

    // Occurrences d'une série remplacées (ou annulées) par un VEVENT à part.
    final remplacees = <String>{
      for (final p in bruts)
        if (_cle(p, 'RECURRENCE-ID') case final k?)
          if (_horodatage(k, p[k]!) case final h?)
            '${p['UID']}|${h.instant.toUtc()}',
    };

    final events = <ClubEvent>[];
    for (final p in bruts) {
      if (p['STATUS'] == 'CANCELLED') continue;
      events.addAll(_toEvents(p, remplacees, limite));
    }
    return events;
  }

  static String? _cle(Map<String, String> p, String nom) {
    for (final k in p.keys) {
      if (k == nom || k.startsWith('$nom;')) return k;
    }
    return null;
  }

  static List<ClubEvent> _toEvents(
      Map<String, String> p, Set<String> remplacees, DateTime limite) {
    final startKey = _cle(p, 'DTSTART');
    if (startKey == null) return const [];
    final debut = _horodatage(startKey, p[startKey]!);
    if (debut == null) return const [];
    final endKey = _cle(p, 'DTEND');
    final fin = endKey == null ? null : _horodatage(endKey, p[endKey]!);
    // Journée entière sans fin : elle dure la journée (RFC 5545).
    final duree = fin != null
        ? fin.mur.difference(debut.mur)
        : (debut.fuseau == _Fuseau.date ? const Duration(days: 1) : null);

    final title = _text(p['SUMMARY'] ?? 'Événement');
    final location = p['LOCATION'] == null || p['LOCATION']!.isEmpty
        ? null
        : _text(p['LOCATION']!);
    final description =
        p['DESCRIPTION'] == null ? null : _description(p['DESCRIPTION']!);

    ClubEvent occurrence(DateTime mur) => ClubEvent(
          title: title,
          start: debut.fuseau.instant(mur),
          end: duree == null ? null : debut.fuseau.instant(mur.add(duree)),
          allDay: debut.fuseau == _Fuseau.date,
          location: location,
          description: description,
        );

    final rrule = p['RRULE'];
    if (rrule == null) return [occurrence(debut.mur)];

    final exclues = <DateTime>{};
    final exKey = _cle(p, 'EXDATE');
    if (exKey != null) {
      for (final v in p[exKey]!.split(',')) {
        final h = _horodatage(exKey, v);
        if (h != null) exclues.add(h.instant.toUtc());
      }
    }

    return [
      for (final mur in _deplier(rrule, debut, limite))
        if (!exclues.contains(debut.fuseau.instant(mur).toUtc()) &&
            !remplacees
                .contains('${p['UID']}|${debut.fuseau.instant(mur).toUtc()}'))
          occurrence(mur),
    ];
  }

  static const _jours = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  /// Débuts (en heure murale) d'une règle DAILY ou WEEKLY, avec INTERVAL,
  /// BYDAY, WKST, UNTIL et COUNT. Une autre fréquence ne donne rien : mieux
  /// vaut ne rien afficher qu'une date fausse.
  static Iterable<DateTime> _deplier(
      String rrule, _Horodatage debut, DateTime limite) sync* {
    final r = {
      for (final part in rrule.split(';'))
        if (part.split('=') case [final k, final v]) k: v,
    };
    final freq = r['FREQ'];
    if (freq != 'WEEKLY' && freq != 'DAILY') return;
    final intervalle = int.tryParse(r['INTERVAL'] ?? '') ?? 1;
    final nombre = int.tryParse(r['COUNT'] ?? '');
    final jusquAu = r['UNTIL'] == null ? null : _horodatage('', r['UNTIL']!);

    bool depasse(DateTime mur) {
      final instant = debut.fuseau.instant(mur);
      if (instant.isAfter(limite)) return true;
      if (jusquAu == null) return false;
      // UNTIL en date seule : toute la journée est incluse.
      return jusquAu.fuseau == _Fuseau.utc
          ? instant.isAfter(jusquAu.instant)
          : mur
              .isAfter(jusquAu.mur.add(const Duration(hours: 23, minutes: 59)));
    }

    // Décalages des jours retenus depuis le début de semaine (WKST).
    final List<int> decalages;
    final DateTime base;
    if (freq == 'DAILY') {
      decalages = const [0];
      base = debut.mur;
    } else {
      final wkst = _jours.indexOf(r['WKST'] ?? 'MO').clamp(0, 6);
      final jours = (r['BYDAY']?.split(',') ?? const <String>[])
          .map((j) => _jours.indexOf(j.replaceAll(RegExp(r'[^A-Z]'), '')))
          .where((j) => j >= 0)
          .toList();
      if (jours.isEmpty) jours.add(debut.mur.weekday - 1);
      decalages = jours.map((j) => (j - wkst) % 7).toList()..sort();
      base = debut.mur
          .subtract(Duration(days: (debut.mur.weekday - 1 - wkst) % 7));
    }

    final pas = freq == 'DAILY' ? intervalle : 7 * intervalle;
    var n = 0;
    // Garde-fou : au plus 2 000 périodes.
    for (var periode = 0; periode < 2000; periode++) {
      for (final d in decalages) {
        final mur = base.add(Duration(days: periode * pas + d));
        if (mur.isBefore(debut.mur)) continue;
        if (depasse(mur) || (nombre != null && n >= nombre)) return;
        n++;
        yield mur;
      }
    }
  }

  /// 20261105 (journée), 20261105T183000Z (UTC), 20261105T183000 avec
  /// TZID=Europe/Paris, ou sans fuseau (heure locale du téléphone).
  static _Horodatage? _horodatage(String key, String v) {
    final m = RegExp(r'^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z)?)?$')
        .firstMatch(v.trim());
    if (m == null) return null;
    final d = [
      for (var i = 1; i <= 6; i++) int.tryParse(m.group(i) ?? '') ?? 0
    ];
    final mur = DateTime.utc(d[0], d[1], d[2], d[3], d[4], d[5]);
    if (m.group(4) == null) return _Horodatage(mur, _Fuseau.date);
    if (m.group(7) == 'Z') return _Horodatage(mur, _Fuseau.utc);
    final tzid = RegExp(r'TZID="?([^;:"]+)').firstMatch(key)?.group(1);
    return _Horodatage(
        mur, tzid == 'Europe/Paris' ? _Fuseau.paris : _Fuseau.flottant);
  }

  static String _text(String v) => _desechapper(v, ' ').trim();

  /// Description Google : texte échappé ICS contenant du HTML (balises
  /// brutes ou encodées en entités). On garde les retours à la ligne.
  static String? _description(String v) {
    final texte = _desechapper(v, '\n')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(
            RegExp(r'<br\s*/?>|</p>|</div>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll(RegExp(r'&#0?39;|&apos;'), "'")
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    return texte.isEmpty ? null : texte;
  }

  static String _desechapper(String v, String sautDeLigne) =>
      v.replaceAllMapped(
        RegExp(r'\\([\\,;nN])'),
        (m) => switch (m[1]) { 'n' || 'N' => sautDeLigne, final c => c! },
      );
}

/// Date ICS : heure murale (portée par un DateTime UTC, sans décalage) et
/// fuseau pour en faire un instant. Les récurrences avancent en heure
/// murale : 9 h reste 9 h de part et d'autre d'un changement d'heure.
class _Horodatage {
  final DateTime mur;
  final _Fuseau fuseau;

  const _Horodatage(this.mur, this.fuseau);

  DateTime get instant => fuseau.instant(mur);
}

enum _Fuseau {
  date,
  utc,
  paris,
  flottant;

  /// Instant local du téléphone correspondant à l'heure murale [mur].
  DateTime instant(DateTime mur) => switch (this) {
        _Fuseau.date || _Fuseau.flottant => DateTime(
            mur.year, mur.month, mur.day, mur.hour, mur.minute, mur.second),
        _Fuseau.utc => mur.toLocal(),
        _Fuseau.paris => _parisVersUtc(mur).toLocal(),
      };

  /// Heure de Paris → instant UTC. Heure d'été de l'UE : du dernier
  /// dimanche de mars au dernier dimanche d'octobre, à 1 h UTC. Évite une
  /// dépendance de fuseaux pour le seul fuseau du flux.
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
}
