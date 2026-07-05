import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_turn/src/turn/phases/diplomacy_phase.dart';
import 'package:colonizethis_turn/src/turn/turn_pipeline_state.dart';
import 'package:colonizethis_turn/src/turn/turn_resolution_result.dart';
import 'package:colonizethis_turn/src/turn/turn_resolver_config.dart';

void main() {
  const topology = MapTopology();

  TurnResolverConfig config(Orders orders) =>
      TurnResolverConfig(topology: topology, orders: orders);

  TurnResolutionResult runHandlerExpectExit({
    required Game game,
    required Orders orders,
    int turn = 2,
  }) {
    final outcome = diplomacyTurnPhaseHandler(
      TurnPipelineState(game: game),
      config(orders),
      turn,
    );
    expect(outcome, isA<TurnPhaseStepExit>());
    return (outcome as TurnPhaseStepExit).result;
  }

  Game twoGpGame({
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

  Orders diplomaticOrder(DiplomaticOrderType type, {OvertureStage? stage}) =>
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

  group('diplomacyTurnPhaseHandler', () {
    test('continues pipeline when diplomacy resolves without pending input', () {
      final game = twoGpGame(gp2Human: false, score: 50);
      final outcome = diplomacyTurnPhaseHandler(
        TurnPipelineState(game: game),
        config(const Orders()),
        2,
      );
      expect(outcome, isA<TurnPhaseStepContinue>());
    });

    test('exits with TurnResolutionPendingOvertures for human target', () {
      final game = twoGpGame(
        gp2Human: true,
        score: 50,
        gp1Treasury: overtureConsulateCost + 100,
      );
      final orders = diplomaticOrder(
        DiplomaticOrderType.establishOverture,
        stage: OvertureStage.tradeConsulate,
      );

      final result = runHandlerExpectExit(game: game, orders: orders);

      expect(result, isA<TurnResolutionPendingOvertures>());
      final pending = result as TurnResolutionPendingOvertures;
      expect(pending.pendingOvertures.single.targetFactionId, 'gp2');
    });

    test('exits with TurnResolutionPendingFtp for human target', () {
      final game = twoGpGame(
        gp2Human: true,
        score: 70,
        overtures: const [
          OvertureState(
            gpId: 'gp1',
            targetId: 'gp2',
            stage: OvertureStage.embassy,
          ),
          OvertureState(
            gpId: 'gp2',
            targetId: 'gp1',
            stage: OvertureStage.embassy,
          ),
        ],
      );
      final orders = diplomaticOrder(DiplomaticOrderType.establishFtp);

      final result = runHandlerExpectExit(game: game, orders: orders);

      expect(result, isA<TurnResolutionPendingFtp>());
      final pending = result as TurnResolutionPendingFtp;
      expect(pending.pendingFtpOffers!.single.targetGpId, 'gp2');
    });

    test('exits with TurnResolutionPendingIntervention for embassy holder', () {
      const ow = 'oldWorld';
      const minorProvId = '$ow|M1';
      final game = Game(
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
      final orders = Orders(
        diplomaticOrdersByPlayerId: const {
          'gp2': [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'minor1',
            ),
          ],
        },
      );

      final result = runHandlerExpectExit(game: game, orders: orders);

      expect(result, isA<TurnResolutionPendingIntervention>());
      expect(
        (result as TurnResolutionPendingIntervention)
            .pendingInterventions
            .single
            .interveningGpId,
        'gp1',
      );
    });

    test('exits with TurnResolutionPendingCallToArms for human formal ally', () {
      final game = TestFixtures.minimalGame(
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
      final orders = Orders(
        diplomaticOrdersByPlayerId: const {
          'gp3': [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp2',
            ),
          ],
        },
      );

      final result = runHandlerExpectExit(game: game, orders: orders);

      expect(result, isA<TurnResolutionPendingCallToArms>());
      final pending = result as TurnResolutionPendingCallToArms;
      expect(pending.pendingCallToArms!.single.allyGpId, 'gp1');
      expect(pending.pendingCallToArms!.single.defenderGpId, 'gp2');
      expect(pending.pendingCallToArms!.single.aggressorGpId, 'gp3');
    });
  });
}
