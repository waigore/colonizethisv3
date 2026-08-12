import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'capital_and_gp_fall_reassignment_cases.dart';
import '../world_test_support/world_test_support.dart';

void main() {
  group('applyCapitalReassignmentAfterCombat (Great Power)', () {
    for (final case_ in gpCapitalReassignmentOutcomeCases) {
      test(case_.description, () {
        case_.verify(
          applyCapitalReassignmentAfterCombat(case_.game, kEmptyMapTopology),
        );
      });
    }
    for (final case_ in gpCapitalReassignmentThrowCases) {
      test(case_.description, () {
        expect(
          () => applyCapitalReassignmentAfterCombat(
            case_.game,
            kEmptyMapTopology,
          ),
          throwsA(isA<CapitalReassignmentFatalError>()),
        );
      });
    }
  });

  group('applyFactionCapitalReassignmentAfterCombat (Minor/Tribe)', () {
    for (final case_ in factionCapitalReassignmentOutcomeCases) {
      test(case_.description, () {
        case_.verify(
          applyFactionCapitalReassignmentAfterCombat(
            case_.game,
            kEmptyMapTopology,
          ),
        );
      });
    }
    for (final case_ in factionCapitalReassignmentThrowCases) {
      test(case_.description, () {
        expect(
          () => applyFactionCapitalReassignmentAfterCombat(
            case_.game,
            kEmptyMapTopology,
          ),
          throwsA(isA<CapitalReassignmentFatalError>()),
        );
      });
    }

    test('leaves minor capital untouched when minor still owns it', () {
      final result = applyFactionCapitalReassignmentAfterCombat(
        factionCapitalReassignmentGame(
          id: 'g-minor-owns',
          oldWorldProvinces: const [
            Province(id: 'oldWorld|mcap', regionId: 'oldWorld', ownerId: 'm1'),
          ],
          players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
          minorNations: [
            MinorNation(
              id: 'm1',
              capitalProvinceId: 'oldWorld|mcap',
              capitalTile: capitalTileFor('oldWorld|mcap'),
            ),
          ],
        ),
        kEmptyMapTopology,
      );
      expect(result.minorNations.single.capitalProvinceId, 'oldWorld|mcap');
    });

    test('reassigns both minor and tribe in a single pass', () {
      final result = applyFactionCapitalReassignmentAfterCombat(
        factionCapitalReassignmentGame(
          id: 'g-minor-and-tribe',
          oldWorldProvinces: const [
            Province(id: 'oldWorld|mcap', regionId: 'oldWorld', ownerId: 'p2'),
            Province(
              id: 'oldWorld|malt',
              regionId: 'oldWorld',
              ownerId: 'm1',
              townTileKey: 'oldWorld|malt|5|6',
            ),
          ],
          newWorldProvinces: const [
            Province(id: 'newWorld|tcap', regionId: 'newWorld', ownerId: 'p2'),
            Province(
              id: 'newWorld|talt',
              regionId: 'newWorld',
              ownerId: 't1',
              townTileKey: 'newWorld|talt|7|8',
            ),
          ],
          players: const [Player(id: 'p2', displayName: 'P2', isHuman: true)],
          minorNations: [
            MinorNation(
              id: 'm1',
              capitalProvinceId: 'oldWorld|mcap',
              capitalTile: capitalTileFor('oldWorld|mcap'),
            ),
          ],
          tribes: [
            Tribe(
              id: 't1',
              capitalProvinceId: 'newWorld|tcap',
              capitalTile: capitalTileFor('newWorld|tcap'),
            ),
          ],
        ),
        kEmptyMapTopology,
      );
      expect(result.minorNations.single.capitalProvinceId, 'oldWorld|malt');
      expect(result.tribes.single.capitalProvinceId, 'newWorld|talt');
    });
  });
}
