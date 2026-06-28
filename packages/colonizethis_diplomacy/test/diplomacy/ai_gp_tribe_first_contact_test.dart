import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const _ow = 'oldWorld';
const _nw = 'newWorld';
const _topology = MapTopology(nodes: [], edges: []);

/// Two Great Powers (one human, one AI) that both hold full visibility into the
/// single New World tribe colony tile. No GP–Tribe relation exists yet.
Game _gameWithHumanAndAiGp({Map<String, bool> aiControl = const {}}) {
  return Game(
    id: 'g',
    worldState: const WorldState(
      turnState: TurnState(phase: TurnPhase.endOfTurn, turnNumber: 4),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$_ow|p1', regionId: _ow, ownerId: 'gp1'),
          Province(id: '$_ow|p2', regionId: _ow, ownerId: 'gp2'),
        ],
      ),
      newWorld: RegionData(
        provinces: [Province(id: '$_nw|t1', regionId: _nw, ownerId: 'tribe1')],
      ),
      playerVisibilityByTile: {
        'gp1': {'$_nw|t1|0|0': 'fullyVisible'},
        'gp2': {'$_nw|t1|0|0': 'fullyVisible'},
      },
      tileKeysByRegionAndProvince: {
        _nw: {
          '$_nw|t1': ['$_nw|t1|0|0'],
        },
      },
    ),
    players: const [
      Player(id: 'gp1', displayName: 'Spain', isHuman: true),
      Player(id: 'gp2', displayName: 'France', isHuman: false),
    ],
    tribes: const [Tribe(id: 'tribe1', displayName: 'Maya')],
    aiControlByGpId: aiControl,
    diplomacyRelations: const [],
  );
}

void main() {
  suppressLogsForTests();

  group('applyAiGpTribeFirstContactRelations', () {
    test('AI GP with NW visibility gets AT_PEACE score-50 relation', () {
      final game = _gameWithHumanAndAiGp();

      final next = applyAiGpTribeFirstContactRelations(
        game: game,
        topology: _topology,
      );

      final rel = getRelation(next, 'gp2', 'tribe1');
      expect(rel, isNotNull);
      expect(rel!.state, RelationState.atPeace);
      expect(rel.score, relationScoreNeutral);
      expect(rel.level, RelationLevel.neutral);
      expect(rel.sinceTurn, 4);
    });

    test('human GP is skipped during turn resolution', () {
      final game = _gameWithHumanAndAiGp();

      final next = applyAiGpTribeFirstContactRelations(
        game: game,
        topology: _topology,
      );

      // Only the AI GP relation is created; the human relation/herald is left
      // for the app layer (`syncGpTribeFirstContact`).
      expect(getRelation(next, 'gp1', 'tribe1'), isNull);
      expect(next.diplomacyRelations.length, 1);
    });

    test('does not duplicate an existing AI GP relation on a second pass', () {
      final game = _gameWithHumanAndAiGp();

      final first = applyAiGpTribeFirstContactRelations(
        game: game,
        topology: _topology,
      );
      final second = applyAiGpTribeFirstContactRelations(
        game: first,
        topology: _topology,
      );

      expect(second.diplomacyRelations.length, 1);
    });

    test('negative: AI GP with no NW tile visibility gets no relation', () {
      final base = _gameWithHumanAndAiGp();
      final game = base.copyWith(
        worldState: base.worldState.copyWith(
          playerVisibilityByTile: const {
            'gp1': {'$_nw|t1|0|0': 'fullyVisible'},
            'gp2': {'$_ow|p2|0|0': 'fullyVisible'},
          },
        ),
      );

      final next = applyAiGpTribeFirstContactRelations(
        game: game,
        topology: _topology,
      );

      expect(getRelation(next, 'gp2', 'tribe1'), isNull);
      expect(next.diplomacyRelations, isEmpty);
    });

    test('negative: game with no tribes returns the same instance', () {
      final game = _gameWithHumanAndAiGp().copyWith(tribes: const []);

      final next = applyAiGpTribeFirstContactRelations(
        game: game,
        topology: _topology,
      );

      expect(identical(next, game), isTrue);
    });

    test(
      'observer mode: human GP flagged AI-controlled also gets a relation',
      () {
        final game = _gameWithHumanAndAiGp(
          aiControl: const {'gp1': true, 'gp2': true},
        );

        final next = applyAiGpTribeFirstContactRelations(
          game: game,
          topology: _topology,
        );

        expect(getRelation(next, 'gp1', 'tribe1'), isNotNull);
        expect(getRelation(next, 'gp2', 'tribe1'), isNotNull);
        expect(next.diplomacyRelations.length, 2);
      },
    );
  });
}
