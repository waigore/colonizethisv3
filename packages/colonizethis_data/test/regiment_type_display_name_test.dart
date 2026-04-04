import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

void main() {
  group('regimentTypeDisplayName', () {
    test('every regimentCatalog id has a non-empty display name', () {
      for (final r in regimentCatalog) {
        final label = regimentTypeDisplayName(r.id);
        expect(label, isNotEmpty);
        expect(
          label,
          isNot(equals(r.id)),
          reason: '${r.id} should map to a human-readable label',
        );
      }
    });

    test('unknown id falls back to id', () {
      expect(
        regimentTypeDisplayName('future_mod_regiment'),
        'future_mod_regiment',
      );
    });

    test('peasant levies label matches GDD roster name', () {
      expect(regimentTypeDisplayName('peasant_levies'), 'Peasant Levies');
    });
  });
}
