import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Tests `processBoycotts` / `autoCancelBoycottsOnWar` (Refs #3753 R6):
/// boycott apply/revoke, subsidy cancellation on apply, and auto-cancel on war.
/// SPEC/game/diplomacy.md § GP–Tribe Rules (Boycott).
Game _game({
  bool gp1HoldsColony = true,
  RelationState gp1gp2State = RelationState.atPeace,
  List<BoycottState> boycotts = const [],
  List<SubsidyState> subsidies = const [],
}) {
  return Game(
    id: 'g-boycott',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 7),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'GP1', isHuman: false),
      Player(id: 'gp2', displayName: 'GP2', isHuman: false),
    ],
    tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        state: gp1gp2State,
      ),
    ],
    colonyStates: gp1HoldsColony
        ? const [
            ColonyState(tribeId: 'tribe1', colonyOfGpId: 'gp1', sinceTurn: 1),
          ]
        : const [],
    boycottStates: boycotts,
    subsidyStates: subsidies,
  );
}

Map<String, List<DiplomaticOrder>> _order(
  String gpId,
  DiplomaticOrderType type,
  String targetId,
) => {
  gpId: [DiplomaticOrder(type: type, targetFactionId: targetId)],
};

void main() {
  group('processBoycotts (apply)', () {
    test('records a BoycottState and appends boycottSet', () {
      final game = _game();
      final result = processBoycotts(
        game,
        _order('gp1', DiplomaticOrderType.boycott, 'gp2'),
        7,
        factionMembership: DiplomacyFactionMembership.from(game),
      );
      expect(result.boycottStates.length, 1);
      final b = result.boycottStates.single;
      expect(b.gpId, 'gp1');
      expect(b.targetGpId, 'gp2');
      expect(b.sinceTurn, 7);
      expect(
        result.diplomaticHistoryEvents
            .where((e) => e.type == DiplomaticEventType.boycottSet)
            .length,
        1,
      );
    });

    test('cancels the target GP subsidy to the issuer colony on apply', () {
      final game = _game(
        subsidies: const [
          SubsidyState(payerId: 'gp2', targetId: 'tribe1', percent: 20),
        ],
      );
      final result = processBoycotts(
        game,
        _order('gp1', DiplomaticOrderType.boycott, 'gp2'),
        7,
        factionMembership: DiplomacyFactionMembership.from(game),
      );
      expect(result.subsidyStates, isEmpty);
      expect(
        result.diplomaticHistoryEvents
            .where((e) => e.type == DiplomaticEventType.subsidyCancelled)
            .length,
        1,
      );
    });

    test('does not apply when the issuer holds no colony', () {
      final game = _game(gp1HoldsColony: false);
      final result = processBoycotts(
        game,
        _order('gp1', DiplomaticOrderType.boycott, 'gp2'),
        7,
        factionMembership: DiplomacyFactionMembership.from(game),
      );
      expect(result.boycottStates, isEmpty);
    });

    test('does not apply when at war with the target', () {
      final game = _game(gp1gp2State: RelationState.atWar);
      final result = processBoycotts(
        game,
        _order('gp1', DiplomaticOrderType.boycott, 'gp2'),
        7,
        factionMembership: DiplomacyFactionMembership.from(game),
      );
      expect(result.boycottStates, isEmpty);
    });

    test('does not duplicate an existing boycott', () {
      final game = _game(
        boycotts: const [
          BoycottState(gpId: 'gp1', targetGpId: 'gp2', sinceTurn: 2),
        ],
      );
      final result = processBoycotts(
        game,
        _order('gp1', DiplomaticOrderType.boycott, 'gp2'),
        7,
        factionMembership: DiplomacyFactionMembership.from(game),
      );
      expect(result.boycottStates.length, 1);
      expect(result.boycottStates.single.sinceTurn, 2);
    });
  });

  group('processBoycotts (revoke)', () {
    test('removes an existing boycott and appends boycottRevoked', () {
      final game = _game(
        boycotts: const [
          BoycottState(gpId: 'gp1', targetGpId: 'gp2', sinceTurn: 2),
        ],
      );
      final result = processBoycotts(
        game,
        _order('gp1', DiplomaticOrderType.revokeBoycott, 'gp2'),
        7,
        factionMembership: DiplomacyFactionMembership.from(game),
      );
      expect(result.boycottStates, isEmpty);
      expect(
        result.diplomaticHistoryEvents
            .where((e) => e.type == DiplomaticEventType.boycottRevoked)
            .length,
        1,
      );
    });

    test('is a no-op when no boycott exists to revoke', () {
      final game = _game();
      final result = processBoycotts(
        game,
        _order('gp1', DiplomaticOrderType.revokeBoycott, 'gp2'),
        7,
        factionMembership: DiplomacyFactionMembership.from(game),
      );
      expect(result.boycottStates, isEmpty);
      expect(
        result.diplomaticHistoryEvents
            .where((e) => e.type == DiplomaticEventType.boycottRevoked),
        isEmpty,
      );
    });
  });

  group('autoCancelBoycottsOnWar', () {
    test('removes a boycott whose pair is now at war and logs revoke', () {
      final game = _game(
        gp1gp2State: RelationState.atWar,
        boycotts: const [
          BoycottState(gpId: 'gp1', targetGpId: 'gp2', sinceTurn: 2),
        ],
      );
      final result = autoCancelBoycottsOnWar(game, 7);
      expect(result.boycottStates, isEmpty);
      expect(
        result.diplomaticHistoryEvents
            .where((e) => e.type == DiplomaticEventType.boycottRevoked)
            .length,
        1,
      );
    });

    test('keeps a boycott whose pair remains at peace', () {
      final game = _game(
        boycotts: const [
          BoycottState(gpId: 'gp1', targetGpId: 'gp2', sinceTurn: 2),
        ],
      );
      final result = autoCancelBoycottsOnWar(game, 7);
      expect(result.boycottStates.length, 1);
    });
  });
}
