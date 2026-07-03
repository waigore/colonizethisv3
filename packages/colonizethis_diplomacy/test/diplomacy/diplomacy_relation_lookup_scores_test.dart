import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy_test_support/colonizethis_diplomacy_test_support.dart';

/// Coverage for the power-score, ship-count, leader-pick, attack-eligibility,
/// and history-ordering helpers in `diplomacy_relation_lookup.dart`
/// (Refs #3290 test migration — per-package coverage gate for
/// `colonizethis_diplomacy`).
void main() {
  group('shipCountForFaction', () {
    test('positive: sums ships across the faction\'s fleets only', () {
      final game = relationLookupGame(
        fleets: [
          diplomacyTestFleet('f1', 'gp1', 2),
          diplomacyTestFleet('f2', 'gp1', 3),
          diplomacyTestFleet('f3', 'gp2', 4),
        ],
      );
      expect(shipCountForFaction(game, 'gp1'), 5);
      expect(shipCountForFaction(game, 'gp2'), 4);
    });

    test('negative: faction with no fleets has zero ships', () {
      expect(shipCountForFaction(relationLookupGame(), 'gp9'), 0);
    });
  });

  group('greatPowerPowerScore', () {
    test('positive: provinces and ships are weighted', () {
      // 2 provinces * 10 + 0 regiments + 3 ships * 5 = 35.
      final game = relationLookupGame(
        players: const [Player(id: 'gp1', displayName: 'A', isHuman: false)],
        oldWorldProvinces: [
          oldWorldOwnedProvince('p1', 'gp1'),
          oldWorldOwnedProvince('p2', 'gp1'),
        ],
        fleets: [diplomacyTestFleet('f1', 'gp1', 3)],
      );
      expect(greatPowerPowerScore(game, 'gp1'), 2 * 10 + 3 * 5);
    });

    test('negative: faction owning nothing scores zero', () {
      final game = relationLookupGame(
        players: const [Player(id: 'gp1', displayName: 'A', isHuman: false)],
      );
      expect(greatPowerPowerScore(game, 'gp1'), 0);
    });
  });

  group('pickUniqueGreatPowerLeaderByPowerScore', () {
    test('negative: no players returns null', () {
      expect(pickUniqueGreatPowerLeaderByPowerScore(relationLookupGame()), isNull);
    });

    test('positive: strictly highest score is the unique leader', () {
      final game = relationLookupGame(
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        oldWorldProvinces: [
          oldWorldOwnedProvince('p1', 'gp1'),
          oldWorldOwnedProvince('p2', 'gp1'),
          oldWorldOwnedProvince('p3', 'gp2'),
        ],
      );
      expect(pickUniqueGreatPowerLeaderByPowerScore(game), 'gp1');
    });

    test('negative: a tie for the top score returns null', () {
      final game = relationLookupGame(
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        oldWorldProvinces: [
          oldWorldOwnedProvince('p1', 'gp1'),
          oldWorldOwnedProvince('p2', 'gp2'),
        ],
      );
      expect(pickUniqueGreatPowerLeaderByPowerScore(game), isNull);
    });
  });

  group('canAttackWithWarOrDeclaring', () {
    test('positive: already at war can attack', () {
      final game = relationLookupGame(
        relations: const [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            state: RelationState.atWar,
          ),
        ],
      );
      expect(canAttackWithWarOrDeclaring(game, 'gp1', 'gp2', const []), isTrue);
    });

    test('positive: declaring war this turn can attack', () {
      final game = relationLookupGame(
        relations: const [
          DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2'),
        ],
      );
      expect(
        canAttackWithWarOrDeclaring(game, 'gp1', 'gp2', const [
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'gp2',
          ),
        ]),
        isTrue,
      );
    });

    test('negative: at peace with no declare-war order cannot attack', () {
      final game = relationLookupGame(
        relations: const [
          DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2'),
        ],
      );
      expect(
        canAttackWithWarOrDeclaring(game, 'gp1', 'gp2', const [
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'gp3',
          ),
        ]),
        isFalse,
      );
    });
  });

  group('diplomaticHistoryForPair', () {
    test('positive: same-turn events ordered by descending intraTurnIndex', () {
      final game = relationLookupGame(
        history: const [
          DiplomaticEvent(
            turn: 5,
            intraTurnIndex: 0,
            type: DiplomaticEventType.declareWar,
            participants: {'gp1', 'gp2'},
          ),
          DiplomaticEvent(
            turn: 5,
            intraTurnIndex: 2,
            type: DiplomaticEventType.peace,
            participants: {'gp1', 'gp2'},
          ),
        ],
      );
      final pair = diplomaticHistoryForPair(game, 'gp1', 'gp2');
      expect(pair.map((e) => e.intraTurnIndex).toList(), [2, 0]);
    });

    test('negative: events not involving both parties are excluded', () {
      final game = relationLookupGame(
        history: const [
          DiplomaticEvent(
            turn: 3,
            intraTurnIndex: 0,
            type: DiplomaticEventType.declareWar,
            participants: {'gp1', 'gp3'},
          ),
        ],
      );
      expect(diplomaticHistoryForPair(game, 'gp1', 'gp2'), isEmpty);
    });
  });
}
