// Composed diplomacy-planner integration for #3753 S16: wires
// `DefaultOrderSuggestionAPI` candidates through `runDiplomacyPlannerWithResult`
// for boycott and breakAlliance (beyond package-level scoring pins in
// `diplomatic_candidate_scoring_*_test.dart`).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/planner_test_helpers.dart';

const _topology = MapTopology(nodes: [], edges: []);

const _backstabberConfig = AIConfig(
  leaderId: 'napoleon',
  personalityId: 'napoleon',
  hiddenAgendaId: 'backstabber',
);

Game _twoGpAtPeaceGame({
  bool formalAlliance = false,
  bool holdsColony = false,
}) {
  return Game(
    id: 'g-diplomacy-planner-wiring',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
      oldWorld: const RegionData(
        provinces: [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
          Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp2'),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'A', isHuman: false),
      Player(id: 'gp2', displayName: 'B', isHuman: false),
    ],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        score: 50,
        level: RelationLevel.neutral,
        state: RelationState.atPeace,
        formalAlliance: formalAlliance,
      ),
    ],
    colonyStates: holdsColony
        ? const [
            ColonyState(tribeId: 'tribe1', colonyOfGpId: 'gp1', sinceTurn: 1),
          ]
        : const [],
    aiControlByGpId: const {'gp1': true},
  );
}

AIWorldSnapshot _neutralSnapshot() => const AIWorldSnapshot(
  playerId: 'gp1',
  threats: ThreatSummary(),
  opportunities: OpportunitySummary(),
  conquest: ConquestSummary(oldWorldProvincesOwned: 5),
  economy: EconomySummary(),
  relations: {},
);

DiplomaticOrder? _chosenOrder({
  required Game game,
  required int turnSeed,
  AIConfig config = _backstabberConfig,
}) {
  final ctx = buildTestPlannerContext(
    game: game,
    topology: _topology,
    nationId: 'gp1',
    primaryGoal: StrategicGoal.diplomacy,
    turnSeed: turnSeed,
    config: config,
  );
  final snapshot = _neutralSnapshot();
  final result = runDiplomacyPlannerWithResult(
    ctx: ctx,
    snapshot: snapshot,
    pass: DiplomacyPlannerPass.nonDeclareWarOnly,
  );
  final orders = result.orders.diplomaticOrdersByPlayerId['gp1'];
  return orders == null || orders.isEmpty ? null : orders.single;
}

void main() {
  group('runDiplomacyPlannerWithResult #3753 S16 wiring', () {
    test(
      'emits breakAlliance when formal alliance is the sole GP candidate',
      () {
        final game = _twoGpAtPeaceGame(formalAlliance: true);
        final chosen = _chosenOrder(game: game, turnSeed: 42);
        expect(chosen, isNotNull);
        expect(chosen!.type, DiplomaticOrderType.breakAlliance);
        expect(chosen.targetFactionId, 'gp2');
      },
    );

    test(
      'emits boycott for a colony-holding backstabber on some diplomacy seed',
      () {
        final game = _twoGpAtPeaceGame(holdsColony: true);
        DiplomaticOrder? boycottChosen;
        for (var seed = 1; seed <= 5000; seed++) {
          final chosen = _chosenOrder(game: game, turnSeed: seed);
          if (chosen?.type == DiplomaticOrderType.boycott &&
              chosen?.targetFactionId == 'gp2') {
            boycottChosen = chosen;
            break;
          }
        }
        expect(
          boycottChosen,
          isNotNull,
          reason:
              'Expected weighted selection to pick boycott toward gp2 within '
              '5000 diplomacy seeds for backstabber + colony holder',
        );
      },
    );

    test('does not emit boycott when the planner GP holds no colony', () {
      final game = _twoGpAtPeaceGame(holdsColony: false);
      for (var seed = 1; seed <= 200; seed++) {
        final chosen = _chosenOrder(game: game, turnSeed: seed);
        expect(chosen?.type, isNot(DiplomaticOrderType.boycott));
      }
    });
  });
}
