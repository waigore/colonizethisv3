import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  const turn = TurnState(phase: TurnPhase.orders, turnNumber: 0);
  final pOld1 = Province(
    id: 'oldWorld|P1',
    regionId: kRegionOldWorld,
    ownerId: 'gp1',
  );
  final pOld2 = Province(id: 'oldWorld|P2', regionId: kRegionOldWorld);
  final pNew1 = Province(
    id: 'newWorld|P3',
    regionId: kRegionNewWorld,
    ownerId: 'gp2',
  );

  WorldState makeWorld({
    List<Province> oldProvinces = const [],
    List<Province> newProvinces = const [],
  }) {
    return WorldState(
      turnState: turn,
      oldWorld: RegionData(provinces: oldProvinces),
      newWorld: RegionData(provinces: newProvinces),
    );
  }

  group('WorldStateProvinceLookup.regionsInOrder (Refs #3710)', () {
    test('yields old world first, then new world, with their region data', () {
      final ws = makeWorld(oldProvinces: [pOld1], newProvinces: [pNew1]);

      final entries = ws.regionsInOrder.toList();

      expect(entries.map((e) => e.regionId), [
        kRegionOldWorld,
        kRegionNewWorld,
      ]);
      expect(identical(entries[0].region, ws.oldWorld), isTrue);
      expect(identical(entries[1].region, ws.newWorld), isTrue);
    });

    test('still yields both regions when one has no provinces', () {
      final ws = makeWorld(oldProvinces: [pOld1]);

      final entries = ws.regionsInOrder.toList();

      expect(entries.map((e) => e.regionId), [
        kRegionOldWorld,
        kRegionNewWorld,
      ]);
      expect(entries[1].region.provinces, isEmpty);
    });
  });

  group('cross-region traversal stays consistent with regionsInOrder', () {
    test(
      'allProvinces equals regionsInOrder province concatenation '
      '(old-then-new)',
      () {
        final ws = makeWorld(
          oldProvinces: [pOld1, pOld2],
          newProvinces: [pNew1],
        );

        final viaRegions = [
          for (final entry in ws.regionsInOrder) ...entry.region.provinces,
        ];

        expect(ws.allProvinces().toList(), viaRegions);
        expect(allProvinces(ws).toList(), viaRegions);
        expect(ws.allProvinces().toList(), [pOld1, pOld2, pNew1]);
      },
    );

    test('forEachRegion visits regions in regionsInOrder order', () {
      final ws = makeWorld(oldProvinces: [pOld1], newProvinces: [pNew1]);

      final seen = <String>[];
      ws.forEachRegion((regionId, _) => seen.add(regionId));

      expect(seen, ws.regionsInOrder.map((e) => e.regionId).toList());
      expect(seen, [kRegionOldWorld, kRegionNewWorld]);
    });
  });
}
