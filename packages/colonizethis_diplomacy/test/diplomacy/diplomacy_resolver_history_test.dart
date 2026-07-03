import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

void main() {
  group('diplomatic history', () {
    test('declare war appends declareWar event', () {
      final game = diplomacyGame(
        id: 'g1',
        turnNumber: 5,
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: true),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 50,
            level: RelationLevel.neutral,
            state: RelationState.atPeace,
          ),
        ],
      );
      final orders = Orders(
        diplomaticOrdersByPlayerId: {
          'gp1': const [
            DiplomaticOrder(type: DiplomaticOrderType.declareWar, targetFactionId: 'gp2'),
          ],
        },
      );
      final after = resolveDiplomacyPhase(game, orders).game;
      expect(after.diplomaticHistoryEvents, isNotEmpty);
      final warEvent = after.diplomaticHistoryEvents
          .where((e) => e.type == DiplomaticEventType.declareWar)
          .toList();
      expect(warEvent.length, 1);
      expect(warEvent.first.participants, contains('gp1'));
      expect(warEvent.first.participants, contains('gp2'));
      expect(warEvent.first.turn, 5);
    });

    test('diplomaticHistoryForPair returns events for pair newest first', () {
      final game = diplomacyGame(
        id: 'g1',
        turnNumber: 10,
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: true),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        diplomaticHistoryEvents: const [
          DiplomaticEvent(
            turn: 1,
            intraTurnIndex: 0,
            type: DiplomaticEventType.declareWar,
            participants: {'gp1', 'gp2'},
            fromFactionId: 'gp1',
            toFactionId: 'gp2',
          ),
          DiplomaticEvent(
            turn: 5,
            intraTurnIndex: 0,
            type: DiplomaticEventType.peace,
            participants: {'gp1', 'gp2'},
            fromFactionId: 'gp1',
            toFactionId: 'gp2',
          ),
        ],
      );
      final list = diplomaticHistoryForPair(game, 'gp1', 'gp2');
      expect(list.length, 2);
      expect(list[0].type, DiplomaticEventType.peace);
      expect(list[0].turn, 5);
      expect(list[1].type, DiplomaticEventType.declareWar);
      expect(list[1].turn, 1);
    });
  });
}
