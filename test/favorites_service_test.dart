import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spiphoto_app/service/favorites_service.dart';

void main() {
  test('favoriClubDepuisFiche lit la fiche photoStats', () {
    final FavoriClub favori = FavoritesService.favoriClubDepuisFiche('60153', {
      'favoriteCount': 3,
      'lastAddedAt': Timestamp.fromMillisecondsSinceEpoch(3000),
      'photoUrl': 'https://exemple.fr/a.jpg',
      'vignetteUrl': 'https://exemple.fr/a-320x320.jpg',
      'ecranUrl': 'https://exemple.fr/a-1456x1920.jpg',
      'albumTitle': 'Venise',
      'membres': {
        'uid-b': {
          'nom': 'Bernard',
          'ajout': Timestamp.fromMillisecondsSinceEpoch(2000),
        },
        'uid-a': {
          'nom': 'Alice',
          'photo': 'https://exemple.fr/alice.png',
          'ajout': Timestamp.fromMillisecondsSinceEpoch(1000),
        },
        // Favori enregistré sans profil : compté, mais pas nommé.
        'uid-c': {'ajout': Timestamp.fromMillisecondsSinceEpoch(3000)},
      },
    });

    expect(favori.mediaId, '60153');
    expect(favori.nbFavoris, 3);
    expect(favori.vignetteUrl, 'https://exemple.fr/a-320x320.jpg');
    expect(favori.albumTitle, 'Venise');
    expect(favori.dernierAjout, DateTime.fromMillisecondsSinceEpoch(3000));
    // Premiers à l'avoir choisie en tête.
    expect(favori.membres.map((m) => m.nom), ['Alice', 'Bernard']);
    expect(favori.membres.first.photoUrl, 'https://exemple.fr/alice.png');
  });

  test('favoriClubDepuisFiche sans membres', () {
    final FavoriClub favori = FavoritesService.favoriClubDepuisFiche('1', {
      'favoriteCount': 1,
      'photoUrl': 'https://exemple.fr/b.jpg',
    });
    expect(favori.membres, isEmpty);
    expect(favori.dernierAjout, isNull);
  });
}
