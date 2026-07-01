import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/diplomacy_game_fixtures.dart';

/// Coverage for `processAlliances` in `alliance_resolver.dart`
/// (Refs #3290 test migration — per-package coverage gate for
/// `colonizethis_diplomacy`).
Game _allianceGame({
  List<Player> players = const [
    Player(id: 'gp1', displayName: 'A', isHuman: false),
    Player(id: 'gp2', displayName: 'B', isHuman: false),
  ],
  List<DiplomacyRelation> relations = const [],
  List<Tribe> tribes = const [],
}) =>
    diplomacyGame(
      id: 'g',
      turnNumber: 7,
      players: players,
      tribes: tribes,
      diplomacyRelations: relations,
    );

DiplomaticOrder _alliance(String target) => DiplomaticOrder(
      type: DiplomaticOrderType.alliance,
      targetFactionId: target,
    );

void main() {
  group('processAlliances', () {
    test('positive: new relation between two GPs becomes Allied', () {
      final game = _allianceGame();
      final membership = DiplomacyFactionMembership.from(game);
      final after = processAlliances(
        game,
        {
          'gp1': [_alliance('gp2')],
        },
        7,
        factionMembership: membership,
      );

      final rel = getRelation(after, 'gp1', 'gp2');
      expect(rel, isNotNull);
      expect(rel!.level, RelationLevel.allied);
      expect(rel.score, relationScoreMinAllied);
      expect(rel.formalAlliance, isTrue);
      expect(rel.sinceTurn, 7);
      expect(
        after.diplomaticHistoryEvents
            .where((e) => e.type == DiplomaticEventType.allianceFormed)
            .length,
        1,
      );
    });

    test('positive: existing low-score relation is clamped up to Allied', () {
      final game = _allianceGame(
        relations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 50,
            level: RelationLevel.neutral,
            state: RelationState.atPeace,
          ),
        ],
      );
      final membership = DiplomacyFactionMembership.from(game);
      final after = processAlliances(
        game,
        {
          'gp1': [_alliance('gp2')],
        },
        9,
        factionMembership: membership,
      );

      final rel = getRelation(after, 'gp1', 'gp2');
      expect(rel!.level, RelationLevel.allied);
      expect(rel.score, relationScoreMinAllied);
      expect(rel.formalAlliance, isTrue);
      expect(rel.lastInteractionTurn, 9);
    });

    test('negative: alliance order targeting a non-GP is ignored', () {
      final game = _allianceGame(
        tribes: const [Tribe(id: 'tribe1', displayName: 'T')],
      );
      final membership = DiplomacyFactionMembership.from(game);
      final after = processAlliances(
        game,
        {
          'gp1': [_alliance('tribe1')],
        },
        7,
        factionMembership: membership,
      );

      expect(getRelation(after, 'gp1', 'tribe1'), isNull);
      expect(after.diplomaticHistoryEvents, isEmpty);
    });

    test('negative: non-alliance order leaves relations unchanged', () {
      final game = _allianceGame();
      final membership = DiplomacyFactionMembership.from(game);
      final after = processAlliances(
        game,
        {
          'gp1': const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp2',
            ),
          ],
        },
        7,
        factionMembership: membership,
      );

      expect(after.diplomacyRelations, isEmpty);
      expect(after.diplomaticHistoryEvents, isEmpty);
    });
  });
}
