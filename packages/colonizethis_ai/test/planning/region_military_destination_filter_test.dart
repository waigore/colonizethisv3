// Unit pins for shared OW/NW military destination partition
// (`region_military_destination_filter.dart`, Refs #3941 step 3).
//
import 'package:colonizethis_ai/src/planning/region_military_destination_filter.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/region_military_destination_filter_test_support.dart';

void main() {
  group('planRegionMilitaryDestinations', () {
    test('empty invadable → null (negative / fall-through)', () {
      final game = regionMilitaryDestinationFilterGame(
        oldWorld: const [],
        newWorld: const [],
      );
      expect(
        planRegionMilitaryDestinations(
          game: game,
          invadableProvinceIdsSorted: const [],
          atWarWithFactionIds: const ['gp2'],
          declaredWarTargetFactionId: 'gp2',
        ),
        isNull,
      );
    });

    test('declared-war target owning invadable → single-owner plan', () {
      final game = regionMilitaryDestinationFilterGame(
        oldWorld: const [
          Province(
            id: 'oldWorld|gp2_a',
            regionId: 'oldWorld',
            ownerId: 'gp2',
          ),
          Province(
            id: 'oldWorld|gp2_b',
            regionId: 'oldWorld',
            ownerId: 'gp2',
          ),
        ],
        newWorld: const [],
      );
      final result = planRegionMilitaryDestinations(
        game: game,
        invadableProvinceIdsSorted: const [
          'oldWorld|gp2_b',
          'oldWorld|gp2_a',
        ],
        atWarWithFactionIds: const [],
        declaredWarTargetFactionId: 'gp2',
      );
      expect(result, isNotNull);
      expect(
        result!.destinationProvinceIdsSorted,
        ['oldWorld|gp2_a', 'oldWorld|gp2_b'],
        reason: 'destinations sorted ascending for determinism',
      );
      expect(result.targetOwnerFactionIdsSorted, ['gp2']);
    });

    test(
      'declared-war target owns nothing invadable → null (negative)',
      () {
        final game = regionMilitaryDestinationFilterGame(
          oldWorld: const [
            Province(
              id: 'oldWorld|gp2_a',
              regionId: 'oldWorld',
              ownerId: 'gp2',
            ),
          ],
          newWorld: const [],
        );
        expect(
          planRegionMilitaryDestinations(
            game: game,
            invadableProvinceIdsSorted: const ['oldWorld|gp2_a'],
            atWarWithFactionIds: const ['gp2'],
            declaredWarTargetFactionId: 'missing',
          ),
          isNull,
        );
      },
    );

    test('at-war owners fallback partitions union + sorted owners', () {
      final game = regionMilitaryDestinationFilterGame(
        oldWorld: const [
          Province(
            id: 'oldWorld|gp2_a',
            regionId: 'oldWorld',
            ownerId: 'gp2',
          ),
          Province(
            id: 'oldWorld|gp1_a',
            regionId: 'oldWorld',
            ownerId: 'gp1',
          ),
        ],
        newWorld: const [
          Province(
            id: 'newWorld|gp2_nw',
            regionId: 'newWorld',
            ownerId: 'gp2',
          ),
        ],
      );
      final result = planRegionMilitaryDestinations(
        game: game,
        invadableProvinceIdsSorted: const [
          'newWorld|gp2_nw',
          'oldWorld|gp1_a',
          'oldWorld|gp2_a',
        ],
        atWarWithFactionIds: const ['gp2'],
      );
      expect(result, isNotNull);
      expect(
        result!.destinationProvinceIdsSorted,
        ['newWorld|gp2_nw', 'oldWorld|gp2_a'],
      );
      expect(result.targetOwnerFactionIdsSorted, ['gp2']);
    });
  });
}
