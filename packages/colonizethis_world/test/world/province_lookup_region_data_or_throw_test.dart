// ignore_for_file: deprecated_member_use

import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

import '../world_test_support/province_lookup_test_support.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

void main() {
  group(
    'WorldStateProvinceLookup.regionDataForIdOrThrow (Refs #2836 item 1)',
    () {
      test('returns oldWorld region by identity for kRegionOldWorld', () {
        final ws = traversalDualRegionWorld(
          oldUnits: [traversalUOld],
          newUnits: [traversalUNew],
        );

        final region = ws.regionDataForIdOrThrow(kRegionOldWorld);

        expect(identical(region, ws.oldWorld), isTrue);
        expect(region.provinces.single.id, 'oldWorld|P1');
      });

      test('returns newWorld region by identity for kRegionNewWorld', () {
        final ws = traversalDualRegionWorld(
          oldUnits: [traversalUOld],
          newUnits: [traversalUNew],
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
        final ws = traversalDualRegionWorld(
          oldUnits: [traversalUOld],
          newUnits: [traversalUNew],
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
