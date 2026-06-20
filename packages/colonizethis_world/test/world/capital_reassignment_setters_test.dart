import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/capital_reassignment.dart';
import 'package:colonizethis_world/src/world/capital_reassignment_fatal.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';
import 'package:colonizethis_world/src/logic_validation_exception.dart';
import 'package:colonizethis_test/test.dart';

import '../test_fixtures.dart';

/// Coverage uplift for `colonizethis_world` (Refs #3290 Phase 1 follow-up).
///
/// Exercises the runtime capital setters and the deterministic reassignment
/// province picker in `lib/src/world/capital_reassignment.dart`.
/// SPEC/game/capital-and-connectivity § Capital loss and reassignment.
CapitalTile _tile(String provinceId, {int x = 1, int y = 2}) => CapitalTile(
  regionId: ProvinceId.regionIdFrom(provinceId),
  provinceId: provinceId,
  x: x,
  y: y,
);

void main() {
  group('pickCapitalProvinceIdForReassignment', () {
    test('throws when no owned provinces are supplied', () {
      expect(
        () => pickCapitalProvinceIdForReassignment(
          const [],
          const MapTopology(),
        ),
        throwsA(isA<LogicValidationException>()),
      );
    });

    test('picks first by ascending id when none are sea-bound', () {
      final picked = pickCapitalProvinceIdForReassignment(
        const ['oldWorld|b', 'oldWorld|a'],
        const MapTopology(),
      );
      expect(picked, 'oldWorld|a');
    });

    test('prefers a sea-bound province when one exists', () {
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'b',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 's1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [TopologyEdge(id1: 'b', id2: 's1')],
      );

      final picked = pickCapitalProvinceIdForReassignment(
        const ['oldWorld|a', 'oldWorld|b'],
        topology,
      );
      expect(picked, 'oldWorld|b');
    });
  });

  group('setCapitalForReassignment', () {
    test('updates only the targeted player capital fields', () {
      final game = TestFixtures.minimalGame(
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: false),
        ],
      );

      final result = setCapitalForReassignment(
        game: game,
        playerId: 'p1',
        provinceId: 'oldWorld|alt',
        tile: _tile('oldWorld|alt'),
      );

      expect(
        result.players.firstWhere((p) => p.id == 'p1').capitalProvinceId,
        'oldWorld|alt',
      );
      expect(
        result.players.firstWhere((p) => p.id == 'p2').capitalProvinceId,
        isNull,
      );
    });

    test('throws when tile province does not match target province', () {
      final game = TestFixtures.minimalGame(
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );

      expect(
        () => setCapitalForReassignment(
          game: game,
          playerId: 'p1',
          provinceId: 'oldWorld|alt',
          tile: _tile('oldWorld|other'),
        ),
        throwsA(isA<CapitalReassignmentFatalError>()),
      );
    });
  });

  group('setCapitalForMinorReassignment', () {
    test('updates the targeted minor nation capital fields', () {
      final game = TestFixtures.minimalGame(
        minorNations: const [MinorNation(id: 'm1')],
      );

      final result = setCapitalForMinorReassignment(
        game: game,
        minorId: 'm1',
        provinceId: 'oldWorld|malt',
        tile: _tile('oldWorld|malt'),
      );

      expect(result.minorNations.single.capitalProvinceId, 'oldWorld|malt');
    });

    test('throws when tile province does not match', () {
      final game = TestFixtures.minimalGame(
        minorNations: const [MinorNation(id: 'm1')],
      );

      expect(
        () => setCapitalForMinorReassignment(
          game: game,
          minorId: 'm1',
          provinceId: 'oldWorld|malt',
          tile: _tile('oldWorld|other'),
        ),
        throwsA(isA<CapitalReassignmentFatalError>()),
      );
    });
  });

  group('setCapitalForTribeReassignment', () {
    test('updates the targeted tribe capital fields', () {
      final game = TestFixtures.minimalGame(
        tribes: const [Tribe(id: 't1')],
      );

      final result = setCapitalForTribeReassignment(
        game: game,
        tribeId: 't1',
        provinceId: 'newWorld|talt',
        tile: _tile('newWorld|talt'),
      );

      expect(result.tribes.single.capitalProvinceId, 'newWorld|talt');
    });

    test('throws when tile province does not match', () {
      final game = TestFixtures.minimalGame(
        tribes: const [Tribe(id: 't1')],
      );

      expect(
        () => setCapitalForTribeReassignment(
          game: game,
          tribeId: 't1',
          provinceId: 'newWorld|talt',
          tile: _tile('newWorld|other'),
        ),
        throwsA(isA<CapitalReassignmentFatalError>()),
      );
    });
  });

  group('applyGreatPowerCapitalProvinceTownDevelopment', () {
    test('sets town development level 4 for the matched province', () {
      final game = TestFixtures.minimalGame(
        oldWorld: const RegionData(
          provinces: [
            Province(id: 'oldWorld|cap', regionId: 'oldWorld', ownerId: 'p1'),
            Province(id: 'oldWorld|other', regionId: 'oldWorld', ownerId: 'p1'),
          ],
        ),
      );

      final next = applyGreatPowerCapitalProvinceTownDevelopment(
        game.worldState,
        'oldWorld',
        'oldWorld|cap',
      );

      final cap = next.tryGetProvince('oldWorld|cap');
      final other = next.tryGetProvince('oldWorld|other');
      expect(cap?.townDevelopmentLevel, 4);
      expect(other?.townDevelopmentLevel, 0);
    });

    test('accepts a bare local capital id', () {
      final game = TestFixtures.minimalGame(
        oldWorld: const RegionData(
          provinces: [
            Province(id: 'oldWorld|cap', regionId: 'oldWorld', ownerId: 'p1'),
          ],
        ),
      );

      final next = applyGreatPowerCapitalProvinceTownDevelopment(
        game.worldState,
        'oldWorld',
        'cap',
      );

      expect(next.tryGetProvince('oldWorld|cap')?.townDevelopmentLevel, 4);
    });
  });
}
