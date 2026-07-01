// Composed diplomacy-planner integration for #3753 S16: wires
// `DefaultOrderSuggestionAPI` candidates through `runDiplomacyPlannerWithResult`
// for boycott and breakAlliance (beyond package-level scoring pins in
// `diplomatic_candidate_scoring_*_test.dart`).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/planner_test_helpers.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';

const _topology = MapTopology(nodes: [], edges: []);

const _backstabberConfig = AIConfig(
  leaderId: 'napoleon',
  personalityId: 'napoleon',
  hiddenAgendaId: 'backstabber',
);

/// Emits only a percent-subsidy candidate so the composed planner wiring test
/// can pin [runDiplomacyPlannerWithResult] without overture/declare-war noise.
final class _SetSubsidyOnlySuggestionAPI extends DefaultOrderSuggestionAPI {
  const _SetSubsidyOnlySuggestionAPI(this.targetId);

  final String targetId;

  @override
  List<DiplomaticOrder> suggestDiplomaticOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    Map<String, TileMapResult>? tileMapByRegion,
    IncrementalCandidateValidator? sharedCandidateValidator,
  }) {
    return [
      DiplomaticOrder(
        type: DiplomaticOrderType.setSubsidy,
        targetFactionId: targetId,
        amount: kSubsidyPercentDefault,
      ),
    ];
  }
}

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
  OrderSuggestionAPI? suggestionAPI,
}) {
  final ctx = buildTestPlannerContext(
    game: game,
    topology: _topology,
    nationId: 'gp1',
    primaryGoal: StrategicGoal.diplomacy,
    turnSeed: turnSeed,
    config: config,
    suggestionAPI: suggestionAPI ?? const DefaultOrderSuggestionAPI(),
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

    test(
      'emits setSubsidy when it is the sole diplomatic candidate '
      '(Refs #3753 S16)',
      () {
        final game = Game(
          id: 'g-diplomacy-planner-subsidy',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: [
            Player(
              id: 'gp1',
              displayName: 'A',
              isHuman: false,
              treasury: 10000,
              techUnlocked: const {kTechIdDiplomaticExpertise: true},
            ),
          ],
          minorNations: const [MinorNation(id: 'minor1', displayName: 'M')],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'minor1',
              score: 50,
              level: RelationLevel.neutral,
              state: RelationState.atPeace,
            ),
          ],
          overtureStates: const [
            OvertureState(
              gpId: 'gp1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
            ),
          ],
          aiControlByGpId: const {'gp1': true},
        );
        final chosen = _chosenOrder(
          game: game,
          turnSeed: 1,
          suggestionAPI: const _SetSubsidyOnlySuggestionAPI('minor1'),
        );
        expect(chosen, isNotNull);
        expect(chosen!.type, DiplomaticOrderType.setSubsidy);
        expect(chosen.targetFactionId, 'minor1');
        expect(chosen.amount, kSubsidyPercentDefault);
      },
    );
  });
}
