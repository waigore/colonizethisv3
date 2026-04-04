import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

void main() {
  group('shipTypeDisplayName', () {
    test('every NavalStatsCatalog.byId key has a non-empty display name', () {
      for (final id in NavalStatsCatalog.byId.keys) {
        final label = shipTypeDisplayName(id);
        expect(label, isNotEmpty);
        expect(
          label,
          isNot(equals(id)),
          reason: '$id should map to a human-readable label',
        );
      }
    });

    test('unknown id falls back to id', () {
      expect(shipTypeDisplayName('future_ship'), 'future_ship');
    });
  });
}
