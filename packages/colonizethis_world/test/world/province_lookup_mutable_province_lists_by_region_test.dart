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
  final pOld2 = Province(
    id: 'oldWorld|P2',
    regionId: kRegionOldWorld,
    ownerId: 'gp2',
  );
  final pNew1 = Province(
    id: 'newWorld|P3',
    regionId: kRegionNewWorld,
    ownerId: 'gp1',
  );
  final pNew2 = Province(
    id: 'newWorld|P4',
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

  group(
    'WorldStateProvinceLookup.mutableProvinceListsByRegion '
    '(Refs #2836 AC 5)',
    () {
      test('returns both regions keyed by canonical region ids', () {
        final ws = makeWorld(
          oldProvinces: [pOld1, pOld2],
          newProvinces: [pNew1, pNew2],
        );

        final result = ws.mutableProvinceListsByRegion();

        expect(result.keys.toSet(), {kRegionOldWorld, kRegionNewWorld});
        expect(result[kRegionOldWorld], [pOld1, pOld2]);
        expect(result[kRegionNewWorld], [pNew1, pNew2]);
      });

      test('returns empty lists for empty regions', () {
        final ws = makeWorld();

        final result = ws.mutableProvinceListsByRegion();

        expect(result[kRegionOldWorld], isEmpty);
        expect(result[kRegionNewWorld], isEmpty);
      });

      test(
        'returned lists are independent copies — mutating does not change '
        'source WorldState',
        () {
          final ws = makeWorld(
            oldProvinces: [pOld1, pOld2],
            newProvinces: [pNew1],
          );

          final result = ws.mutableProvinceListsByRegion();
          result[kRegionOldWorld]!.clear();
          result[kRegionNewWorld]!.add(pNew2);

          expect(ws.oldWorld.provinces, [pOld1, pOld2]);
          expect(ws.newWorld.provinces, [pNew1]);
        },
      );

      test(
        'two successive calls produce independent list copies (no shared '
        'mutable state between calls)',
        () {
          final ws = makeWorld(
            oldProvinces: [pOld1, pOld2],
            newProvinces: [pNew1],
          );

          final first = ws.mutableProvinceListsByRegion();
          final second = ws.mutableProvinceListsByRegion();

          expect(
            identical(first[kRegionOldWorld], second[kRegionOldWorld]),
            isFalse,
          );
          expect(
            identical(first[kRegionNewWorld], second[kRegionNewWorld]),
            isFalse,
          );

          first[kRegionOldWorld]!.add(pOld1);
          expect(second[kRegionOldWorld], [pOld1, pOld2]);
        },
      );
    },
  );
}
