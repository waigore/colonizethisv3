import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../world_test_support/world_test_support.dart';
import 'capital_reassignment_cases.dart';

void main() {
  _capital_reassignment_testTests();
}

void _capital_reassignment_testTests() {
  group('evaluateCapitalReassignmentEligibility', () {
    for (final case_ in capitalEligibilityCases) {
      test(case_.description, () {
        case_.verify(
          evaluateCapitalReassignmentEligibility(
            state: case_.game,
            playerId: case_.playerId,
            regionId: case_.regionId,
            regionTopology: kEmptyMapTopology,
            excludedProvinceId: case_.excludedProvinceId,
          ),
          case_.game,
        );
      });
    }
  });

  group('pickCapitalProvinceIdForReassignment', () {
    test('throws when no owned provinces are supplied', () {
      expect(
        () => pickCapitalProvinceIdForReassignment(const [], kEmptyMapTopology),
        throwsA(isA<LogicValidationException>()),
      );
    });

    test('picks first by ascending id when none are sea-bound', () {
      final picked = pickCapitalProvinceIdForReassignment(const [
        'oldWorld|b',
        'oldWorld|a',
      ], kEmptyMapTopology);
      expect(picked, 'oldWorld|a');
    });

    test('prefers a sea-bound province when one exists', () {
      final topology = provinceSeaZoneTopology(
        regionId: 'oldWorld',
        provinceLocalId: 'b',
        seaZoneId: 's1',
      );

      final picked = pickCapitalProvinceIdForReassignment(const [
        'oldWorld|a',
        'oldWorld|b',
      ], topology);
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
        tile: capitalTileFor('oldWorld|alt'),
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
          tile: capitalTileFor('oldWorld|other'),
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
        tile: capitalTileFor('oldWorld|malt'),
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
          tile: capitalTileFor('oldWorld|other'),
        ),
        throwsA(isA<CapitalReassignmentFatalError>()),
      );
    });
  });

  group('setCapitalForTribeReassignment', () {
    test('updates the targeted tribe capital fields', () {
      final game = TestFixtures.minimalGame(tribes: const [Tribe(id: 't1')]);

      final result = setCapitalForTribeReassignment(
        game: game,
        tribeId: 't1',
        provinceId: 'newWorld|talt',
        tile: capitalTileFor('newWorld|talt'),
      );

      expect(result.tribes.single.capitalProvinceId, 'newWorld|talt');
    });

    test('throws when tile province does not match', () {
      final game = TestFixtures.minimalGame(tribes: const [Tribe(id: 't1')]);

      expect(
        () => setCapitalForTribeReassignment(
          game: game,
          tribeId: 't1',
          provinceId: 'newWorld|talt',
          tile: capitalTileFor('newWorld|other'),
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
      expect(other?.townDevelopmentLevel, kTownDevelopmentLevelMin);
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
