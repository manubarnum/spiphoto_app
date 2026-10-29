import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spiphoto_app/service/theme_service.dart';

void main() {
  final ThemeService service = ThemeService.instance;

  test('suit le réglage de l\'appareil tant que rien n\'est enregistré',
      () async {
    SharedPreferences.setMockInitialValues({});
    await service.init();
    expect(service.sombre.value, isNull);
  });

  test('lit le choix enregistré (même clé et valeurs que le site)', () async {
    SharedPreferences.setMockInitialValues({'spiphoto-theme': 'light'});
    await service.init();
    expect(service.sombre.value, isFalse);

    SharedPreferences.setMockInitialValues({'spiphoto-theme': 'dark'});
    await service.init();
    expect(service.sombre.value, isTrue);
  });

  test('basculer part du thème affiché et enregistre le choix', () async {
    SharedPreferences.setMockInitialValues({});
    await service.init();
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Appareil en sombre, rien d'enregistré : on passe en jour.
    await service.basculer(sombreAffiche: true);
    expect(service.sombre.value, isFalse);
    expect(prefs.getString('spiphoto-theme'), 'light');

    await service.basculer(sombreAffiche: false);
    expect(service.sombre.value, isTrue);
    expect(prefs.getString('spiphoto-theme'), 'dark');
  });
}
