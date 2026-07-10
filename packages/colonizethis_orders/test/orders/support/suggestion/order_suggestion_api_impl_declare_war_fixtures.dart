// API declare-war suggestion fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const apiImplDeclareWarEmptyTopology = MapTopology(nodes: [], edges: []);

/// Minor at peace with gp1; gp1 has diplomatic expertise and treasury for
/// establishOverture but the declare-war-only pass still surfaces declareWar.
Game apiImplDeclareWarMinorScenarioGame() {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: 'oldWorld|m1',
            regionId: 'oldWorld',
            ownerId: 'minor1',
          ),
        ],
      ),
      newWorld: const RegionData(),
      playerVisibilityByTile: const {
        'gp1': {'oldWorld|m1|0|0': 'fullyVisible'},
      },
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          'oldWorld|m1': const ['oldWorld|m1|0|0'],
        },
      },
    ),
    players: [
      const Player(id: 'gp1', displayName: 'A', isHuman: false).copyWith(
        treasury: 600,
        techUnlocked: const {kTechIdDiplomaticExpertise: true},
      ),
    ],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
  );
}

PlayerView apiImplDeclareWarViewFor(Game game) =>
    buildPlayerView(game, apiImplDeclareWarEmptyTopology, 'gp1');
