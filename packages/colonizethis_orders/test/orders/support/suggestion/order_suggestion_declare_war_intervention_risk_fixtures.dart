// Intervention-risk declare-war fixtures (Refs #2509, #3620, #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_suggestion_colonial_acquisition_fixtures.dart';

/// gp1 has first contact with tribe1 via tile visibility into its NW colony;
/// gp2 and gp3 hold embassy overtures on tribe1 (intervention-risk penalty).
Game interventionRiskDeclareWarScenarioGame({String gameId = 'g-intervention-risk'}) {
  return Game(
    id: gameId,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(
        provinces: [
          Province(
            id: 'oldWorld|home',
            regionId: 'oldWorld',
            ownerId: 'gp1',
          ),
        ],
      ),
      newWorld: const RegionData(
        provinces: [
          Province(
            id: 'newWorld|colony',
            regionId: 'newWorld',
            ownerId: 'tribe1',
          ),
        ],
      ),
      playerVisibilityByTile: const {
        'gp1': {
          'oldWorld|home|0|0': 'fullyVisible',
          'newWorld|colony|0|0': 'fullyVisible',
        },
      },
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          'oldWorld|home': const ['oldWorld|home|0|0'],
        },
        'newWorld': {
          'newWorld|colony': const ['newWorld|colony|0|0'],
        },
      },
    ),
    players: const [
      Player(id: 'gp1', displayName: 'GP1', isHuman: false),
      Player(id: 'gp2', displayName: 'GP2', isHuman: false),
      Player(id: 'gp3', displayName: 'GP3', isHuman: false),
    ],
    tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
    overtureStates: const [
      OvertureState(
        gpId: 'gp2',
        targetId: 'tribe1',
        stage: OvertureStage.embassy,
      ),
      OvertureState(
        gpId: 'gp3',
        targetId: 'tribe1',
        stage: OvertureStage.embassy,
      ),
    ],
  );
}

PlayerView interventionRiskViewFor(Game game) =>
    buildPlayerView(game, colonialAcquisitionTopology, 'gp1');

String interventionRiskDeclareWarOrderKey(DiplomaticOrder o) =>
    '${o.type.name}:${o.targetFactionId}';
