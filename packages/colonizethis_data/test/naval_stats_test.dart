import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:test/test.dart';

void main() {
  group('NavalStatsCatalog.shipStrength', () {
    test('matches explicit weighting for carrack', () {
      const s = NavalStatsCatalog.carrack;
      final durability = s.hull * (1 + (s.armour / 10.0));
      final expected = s.firepower +
          (s.range * 0.4) +
          (s.armour * 0.15) +
          durability +
          (s.movement * 0.1);
      expect(NavalStatsCatalog.shipStrength('carrack'), expected);
    });

    test('unknown type uses default entry stats', () {
      expect(
        NavalStatsCatalog.shipStrength('no_such_ship'),
        NavalStatsCatalog.shipStrength('___unknown___'),
      );
    });
  });
}
