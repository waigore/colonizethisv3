import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Coverage for the power-score, ship-count, leader-pick, attack-eligibility,
/// and history-ordering helpers in `diplomacy_relation_lookup.dart`
/// (Refs #3290 test migration — per-package coverage gate for
/// `colonizethis_diplomacy`).
Game _game({
  List<Player> players = const [],
  List<Province> oldWorldProvinces = const [],
  List<Fleet> fleets = const [],
  List<DiplomacyRelation> relations = const [],
  List<DiplomaticEvent> history = const [],
  int turnNumber = 1,
}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: RegionData(provinces: oldWorldProvinces, units: const []),
      newWorld: const RegionData(),
      fleets: fleets,
    ),
    players: players,
    diplomacyRelations: relations,
    diplomaticHistoryEvents: history,
  );
}

Province _prov(String localId, String owner) =>
    Province(id: 'oldWorld|$localId', regionId: 'oldWorld', ownerId: owner);

Fleet _fleet(String id, String owner, int ships) => Fleet(
      id: id,
      ownerId: owner,
      regionId: 'oldWorld',
      shipTypeIds: List<String>.filled(ships, 'frigate'),
    );

void main() {
  group('shipCountForFaction', () {
    test('positive: sums ships across the faction\'s fleets only', () {
      final game = _game(
        fleets: [
          _fleet('f1', 'gp1', 2),
          _fleet('f2', 'gp1', 3),
          _fleet('f3', 'gp2', 4),
        ],
      );
      expect(shipCountForFaction(game, 'gp1'), 5);
      expect(shipCountForFaction(game, 'gp2'), 4);
    });

    test('negative: faction with no fleets has zero ships', () {
      expect(shipCountForFaction(_game(), 'gp9'), 0);
    });
  });

  group('greatPowerPowerScore', () {
    test('positive: provinces and ships are weighted', () {
      // 2 provinces * 10 + 0 regiments + 3 ships * 5 = 35.
      final game = _game(
        players: const [Player(id: 'gp1', displayName: 'A', isHuman: false)],
        oldWorldProvinces: [_prov('p1', 'gp1'), _prov('p2', 'gp1')],
        fleets: [_fleet('f1', 'gp1', 3)],
      );
      expect(greatPowerPowerScore(game, 'gp1'), 2 * 10 + 3 * 5);
    });

    test('negative: faction owning nothing scores zero', () {
      final game = _game(
        players: const [Player(id: 'gp1', displayName: 'A', isHuman: false)],
      );
      expect(greatPowerPowerScore(game, 'gp1'), 0);
    });
  });

  group('pickUniqueGreatPowerLeaderByPowerScore', () {
    test('negative: no players returns null', () {
      expect(pickUniqueGreatPowerLeaderByPowerScore(_game()), isNull);
    });

    test('positive: strictly highest score is the unique leader', () {
      final game = _game(
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        oldWorldProvinces: [_prov('p1', 'gp1'), _prov('p2', 'gp1'), _prov('p3', 'gp2')],
      );
      expect(pickUniqueGreatPowerLeaderByPowerScore(game), 'gp1');
    });

    test('negative: a tie for the top score returns null', () {
      final game = _game(
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        oldWorldProvinces: [_prov('p1', 'gp1'), _prov('p2', 'gp2')],
      );
      expect(pickUniqueGreatPowerLeaderByPowerScore(game), isNull);
    });
  });

  group('canAttackWithWarOrDeclaring', () {
    test('positive: already at war can attack', () {
      final game = _game(
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
      final game = _game(
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
      final game = _game(
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
      final game = _game(
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
      final game = _game(
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
