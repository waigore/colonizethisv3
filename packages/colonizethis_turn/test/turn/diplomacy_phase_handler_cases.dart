// Shared fixtures for diplomacy_phase_handler_test (Refs #4342 Slice C).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_turn/colonizethis_turn_testing.dart';

const diplomacyPhaseHandlerTopology = MapTopology();

TurnResolverConfig diplomacyPhaseHandlerConfig(Orders orders) =>
    TurnResolverConfig(topology: diplomacyPhaseHandlerTopology, orders: orders);

TurnResolutionResult runDiplomacyHandlerExpectExit({
  required Game game,
  required Orders orders,
  int turn = 2,
}) {
  final outcome = diplomacyTurnPhaseHandler(
    TurnPipelineState(game: game),
    diplomacyPhaseHandlerConfig(orders),
    turn,
  );
  expect(outcome, isA<TurnPhaseStepExit>());
  return (outcome as TurnPhaseStepExit).result;
}

Game diplomacyPhaseHandlerTwoGpGame({
  required bool gp2Human,
  required int score,
  List<OvertureState> overtures = const [],
  int gp1Treasury = 0,
}) =>
    TestFixtures.minimalGame(
      id: 'diplomacy-phase',
      turnNumber: 2,
      players: [
        Player(
          id: 'gp1',
          displayName: 'GP1',
          isHuman: false,
          treasury: gp1Treasury,
        ),
        Player(id: 'gp2', displayName: 'GP2', isHuman: gp2Human),
      ],
      diplomacyRelations: [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          score: score,
          level: RelationLevel.friendly,
          state: RelationState.atPeace,
        ),
      ],
      overtureStates: overtures,
    );

Orders diplomacyPhaseHandlerOrder(
  DiplomaticOrderType type, {
  OvertureStage? stage,
}) =>
    Orders(
      diplomaticOrdersByPlayerId: {
        'gp1': [
          DiplomaticOrder(
            type: type,
            targetFactionId: 'gp2',
            overtureStage: stage,
          ),
        ],
      },
    );

Game diplomacyPhaseHandlerInterventionGame() {
  const ow = 'oldWorld';
  const minorProvId = '$ow|M1';
  return Game(
    id: 'intervention',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
      oldWorld: RegionData(
        provinces: const [
          Province(id: minorProvId, regionId: ow, ownerId: 'minor1'),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'Human', isHuman: true),
      Player(id: 'gp2', displayName: 'Aggressor', isHuman: false),
    ],
    minorNations: const [
      MinorNation(id: 'minor1', displayName: 'Minor 1'),
    ],
    diplomacyRelations: const [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'minor1',
        state: RelationState.atPeace,
      ),
      DiplomacyRelation(
        factionId1: 'gp2',
        factionId2: 'minor1',
        state: RelationState.atPeace,
      ),
    ],
    overtureStates: const [
      OvertureState(
        gpId: 'gp1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
  );
}

Orders diplomacyPhaseHandlerInterventionOrders() => Orders(
      diplomaticOrdersByPlayerId: const {
        'gp2': [
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'minor1',
          ),
        ],
      },
    );

Game diplomacyPhaseHandlerCallToArmsGame() => TestFixtures.minimalGame(
      id: 'cta',
      turnNumber: 2,
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < kObserverConquestMinOwProvincesPerGp; i++)
            Province(
              id: 'oldWorld|gp3_$i',
              regionId: 'oldWorld',
              ownerId: 'gp3',
            ),
        ],
      ),
      players: const [
        Player(id: 'gp1', displayName: 'GP1', isHuman: true),
        Player(id: 'gp2', displayName: 'GP2', isHuman: true),
        Player(id: 'gp3', displayName: 'GP3', isHuman: false),
      ],
      diplomacyRelations: [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          score: 80,
          level: RelationLevel.allied,
          state: RelationState.atPeace,
          formalAlliance: true,
        ),
        DiplomacyRelation(
          factionId1: 'gp2',
          factionId2: 'gp3',
          state: RelationState.atPeace,
        ),
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp3',
          state: RelationState.atPeace,
        ),
      ],
    );

Orders diplomacyPhaseHandlerCallToArmsOrders() => Orders(
      diplomaticOrdersByPlayerId: const {
        'gp3': [
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'gp2',
          ),
        ],
      },
    );
