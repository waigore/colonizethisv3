import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('greatPowerDefaultColorRgb', () {
    test('contains exactly the seven GP ids', () {
      expect(greatPowerDefaultColorRgb.length, 7);
      expect(greatPowerDefaultColorRgb.containsKey('england'), isTrue);
      expect(greatPowerDefaultColorRgb.containsKey('france'), isTrue);
      expect(greatPowerDefaultColorRgb.containsKey('spain'), isTrue);
      expect(greatPowerDefaultColorRgb.containsKey('portugal'), isTrue);
      expect(greatPowerDefaultColorRgb.containsKey('netherlands'), isTrue);
      expect(greatPowerDefaultColorRgb.containsKey('prussia'), isTrue);
      expect(greatPowerDefaultColorRgb.containsKey('sweden'), isTrue);
    });

    test('Portugal has GDD green (90, 160, 90)', () {
      final rgb = greatPowerDefaultColorRgb['portugal']!;
      expect(rgb.$1, 90);
      expect(rgb.$2, 160);
      expect(rgb.$3, 90);
    });
  });

  group('greatPowerColorOptions', () {
    test('has seven options in fixed order', () {
      expect(greatPowerColorOptions.length, 7);
      expect(greatPowerColorOptions[0].$2, 'Red');
      expect(greatPowerColorOptions[3].$2, 'Green');
    });
  });
}
