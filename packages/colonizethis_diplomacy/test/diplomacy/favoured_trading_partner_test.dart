import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Favoured trading partner lookup (Refs #3753 R7.1): the GP a Minor/Tribe
/// trades with preferentially — the colony suzerain when colonised, else the
/// highest-decimal-relation GP (ties break by ascending faction id), else null.
/// SPEC/game/diplomacy.md § Favoured trading partner (Refs #3753 R7.1).
Game _game({
  List<Player> players = const [
    Player(id: 'gpA', displayName: 'A', isHuman: false),
    Player(id: 'gpB', displayName: 'B', isHuman: false),
  ],
  List<DiplomacyRelation> relations = const [],
  List<ColonyState> colonyStates = const [],
}) => Game(
  id: 'ftp-lookup-test',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
    oldWorld: const RegionData(),
    newWorld: const RegionData(),
  ),
  players: players,
  diplomacyRelations: relations,
  colonyStates: colonyStates,
);

DiplomacyRelation _rel(String gpId, String targetId, num score) =>
    DiplomacyRelation(
      factionId1: gpId,
      factionId2: targetId,
      score: score,
      level: scoreToLevel(score),
    );

void main() {
  group('favouredTradingPartner (Refs #3753 R7.1)', () {
    test('positive: colony suzerain wins regardless of higher relation', () {
      // gpB holds a higher relation with the Tribe, but gpA is the suzerain.
      final game = _game(
        relations: [_rel('gpA', 'tribe1', 40.0), _rel('gpB', 'tribe1', 90.0)],
        colonyStates: const [
          ColonyState(tribeId: 'tribe1', colonyOfGpId: 'gpA', sinceTurn: 3),
        ],
      );
      expect(favouredTradingPartner(game, 'tribe1'), 'gpA');
    });

    test('positive: independent Tribe → highest-relation GP (72 vs 68)', () {
      final game = _game(
        relations: [_rel('gpA', 'tribe1', 72.0), _rel('gpB', 'tribe1', 68.0)],
      );
      expect(favouredTradingPartner(game, 'tribe1'), 'gpA');
    });

    test('positive: Minor Nation → highest-relation GP (72 vs 68)', () {
      final game = _game(
        relations: [_rel('gpA', 'minor1', 72.0), _rel('gpB', 'minor1', 68.0)],
      );
      expect(favouredTradingPartner(game, 'minor1'), 'gpA');
    });

    test('positive: equal scores break by ascending faction id', () {
      // gpB listed first to prove order independence; gpA (smaller id) wins.
      final game = _game(
        players: const [
          Player(id: 'gpB', displayName: 'B', isHuman: false),
          Player(id: 'gpA', displayName: 'A', isHuman: false),
        ],
        relations: [_rel('gpB', 'tribe1', 60.0), _rel('gpA', 'tribe1', 60.0)],
      );
      expect(favouredTradingPartner(game, 'tribe1'), 'gpA');
    });

    test('positive: decimal precision decides a near tie (60.1 vs 60.0)', () {
      final game = _game(
        relations: [_rel('gpA', 'minor1', 60.0), _rel('gpB', 'minor1', 60.1)],
      );
      expect(favouredTradingPartner(game, 'minor1'), 'gpB');
    });

    test('negative: no GP holds a relation → null', () {
      final game = _game(relations: const []);
      expect(favouredTradingPartner(game, 'minor1'), isNull);
    });

    test('negative: only unrelated GPs (relations with other targets) → null', () {
      final game = _game(
        relations: [_rel('gpA', 'minorOther', 80.0)],
      );
      expect(favouredTradingPartner(game, 'minor1'), isNull);
    });

    test(
      'negative: a single GP with a relation is the favoured partner',
      () {
        final game = _game(relations: [_rel('gpB', 'tribe1', 30.0)]);
        expect(favouredTradingPartner(game, 'tribe1'), 'gpB');
      },
    );
  });
}
