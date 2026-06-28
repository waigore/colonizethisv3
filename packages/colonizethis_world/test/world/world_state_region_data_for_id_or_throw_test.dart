import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';

void main() {
  group(
    'WorldStateProvinceLookup.regionDataForIdOrThrow (Refs #2836 item 1)',
    () {
      const pOld = Province(
        id: 'oldWorld|P1',
        regionId: kRegionOldWorld,
        ownerId: 'o',
      );
      const pNew = Province(
        id: 'newWorld|P2',
        regionId: kRegionNewWorld,
        ownerId: 'n',
      );
      final uOld = Unit(
        id: 'u_old',
        type: kUnitTypeExplorer,
        ownerId: 'o',
        locationProvinceId: 'oldWorld|P1',
      );
      final uNew = Unit(
        id: 'u_new',
        type: kUnitTypeExplorer,
        ownerId: 'n',
        locationProvinceId: 'newWorld|P2',
      );

      test('returns oldWorld region by identity for kRegionOldWorld', () {
        final ws = TestFixtures.worldStateAtOrdersPhase(
          oldWorld: RegionData(provinces: const [pOld], units: [uOld]),
          newWorld: RegionData(provinces: const [pNew], units: [uNew]),
        );

        final region = ws.regionDataForIdOrThrow(kRegionOldWorld);

        expect(identical(region, ws.oldWorld), isTrue);
        expect(region.provinces.single.id, 'oldWorld|P1');
      });

      test('returns newWorld region by identity for kRegionNewWorld', () {
        final ws = TestFixtures.worldStateAtOrdersPhase(
          oldWorld: RegionData(provinces: const [pOld], units: [uOld]),
          newWorld: RegionData(provinces: const [pNew], units: [uNew]),
        );

        final region = ws.regionDataForIdOrThrow(kRegionNewWorld);

        expect(identical(region, ws.newWorld), isTrue);
        expect(region.provinces.single.id, 'newWorld|P2');
      });

      test('throws StateError on unknown regionId with id in message', () {
        final ws = TestFixtures.emptyWorldState();

        expect(
          () => ws.regionDataForIdOrThrow('mars'),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('mars'),
            ),
          ),
        );
      });

      test('throws StateError on empty regionId', () {
        final ws = TestFixtures.emptyWorldState();

        expect(() => ws.regionDataForIdOrThrow(''), throwsA(isA<StateError>()));
      });

      test('agrees with nullable regionDataForId for canonical regionIds', () {
        final ws = TestFixtures.worldStateAtOrdersPhase(
          oldWorld: RegionData(provinces: const [pOld], units: [uOld]),
          newWorld: RegionData(provinces: const [pNew], units: [uNew]),
        );

        expect(
          identical(
            ws.regionDataForIdOrThrow(kRegionOldWorld),
            ws.regionDataForId(kRegionOldWorld),
          ),
          isTrue,
        );
        expect(
          identical(
            ws.regionDataForIdOrThrow(kRegionNewWorld),
            ws.regionDataForId(kRegionNewWorld),
          ),
          isTrue,
        );
      });

      test('returns empty regions for empty world state without throwing', () {
        final ws = TestFixtures.emptyWorldState();

        final ow = ws.regionDataForIdOrThrow(kRegionOldWorld);
        final nw = ws.regionDataForIdOrThrow(kRegionNewWorld);

        expect(ow.provinces, isEmpty);
        expect(ow.units, isEmpty);
        expect(nw.provinces, isEmpty);
        expect(nw.units, isEmpty);
      });
    },
  );
}
