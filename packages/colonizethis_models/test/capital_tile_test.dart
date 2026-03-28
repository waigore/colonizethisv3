import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('CapitalTile.parseTownTileKey', () {
    test('parses valid key matching province', () {
      final t = CapitalTile.parseTownTileKey(
        'oldWorld|p1|3|4',
        'oldWorld|p1',
      );
      expect(t.regionId, 'oldWorld');
      expect(t.provinceId, 'oldWorld|p1');
      expect(t.x, 3);
      expect(t.y, 4);
      expect(t.toTileKey(), 'oldWorld|p1|3|4');
    });

    test('throws when province id mismatches', () {
      expect(
        () => CapitalTile.parseTownTileKey('oldWorld|p1|0|0', 'oldWorld|p2'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when too few segments', () {
      expect(
        () => CapitalTile.parseTownTileKey('a|b|c', 'a|b'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when x y not int', () {
      expect(
        () => CapitalTile.parseTownTileKey('oldWorld|p1|x|0', 'oldWorld|p1'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when empty', () {
      expect(
        () => CapitalTile.parseTownTileKey('', 'oldWorld|p1'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
