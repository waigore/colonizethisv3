import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('Player', () {
    test('toJson/fromJson round-trip', () {
      const p = Player(id: 'p1', displayName: 'Spain', isHuman: true);
      final json = p.toJson();
      final p2 = Player.fromJson(json);
      expect(p2.id, 'p1');
      expect(p2.displayName, 'Spain');
      expect(p2.isHuman, true);
      expect(p2.stockpile, Stockpile.empty);
      expect(p2.workerPool, WorkerPool.empty);
      expect(p2.treasury, 0);
    });
    test('equality', () {
      const a = Player(id: 'p1', displayName: 'Spain', isHuman: true);
      const b = Player(id: 'p1', displayName: 'Spain', isHuman: true);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
    test('equality false when different', () {
      const a = Player(id: 'p1', displayName: 'Spain', isHuman: true);
      const b = Player(id: 'p2', displayName: 'Spain', isHuman: true);
      expect(a == b, false);
      const c = Player(id: 'p1', displayName: 'France', isHuman: true);
      expect(a == c, false);
      expect(a == Object(), false);
    });
    test('toJson/fromJson round-trip with capital and techUnlocked', () {
      const cap = CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'p1',
        x: 2,
        y: 3,
      );
      final p = Player(
        id: 'p1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: cap,
        techUnlocked: {kTechIdRoadConstruction: true},
      );
      final p2 = Player.fromJson(p.toJson());
      expect(p2.capitalProvinceId, 'oldWorld|p1');
      expect(p2.capitalTile?.regionId, 'oldWorld');
      expect(p2.capitalTile?.provinceId, 'p1');
      expect(p2.capitalTile?.x, 2);
      expect(p2.capitalTile?.y, 3);
      expect(p2.techUnlocked?[kTechIdRoadConstruction], true);
    });

    test('fromJson throws for unprefixed capitalProvinceId', () {
      expect(
        () => Player.fromJson({
          'id': 'p1',
          'displayName': 'Spain',
          'isHuman': true,
          'capitalProvinceId': 'p1',
        }),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
