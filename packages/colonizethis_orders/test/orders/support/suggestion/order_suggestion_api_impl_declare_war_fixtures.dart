// API declare-war suggestion fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const apiImplDeclareWarEmptyTopology = MapTopology(nodes: [], edges: []);

/// Minor at peace with gp1; gp1 has diplomatic expertise and treasury for
/// establishOverture but the declare-war-only pass still surfaces declareWar.
Game apiImplDeclareWarMinorScenarioGame() => ordersOwRegionGame(
  id: 'g1',
  turnNumber: 1,
  players: [
    const Player(id: 'gp1', displayName: 'A', isHuman: false).copyWith(
      treasury: 600,
      techUnlocked: const {kTechIdDiplomaticExpertise: true},
    ),
  ],
  oldWorld: RegionData(
    provinces: [
      Province(id: 'oldWorld|m1', regionId: 'oldWorld', ownerId: 'minor1'),
    ],
  ),
  playerVisibilityByTile: const {
    'gp1': {'oldWorld|m1|0|0': 'fullyVisible'},
  },
  tileKeysByRegionAndProvince: const {
    'oldWorld': {
      'oldWorld|m1': ['oldWorld|m1|0|0'],
    },
  },
  minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
);

PlayerView apiImplDeclareWarViewFor(Game game) =>
    buildPlayerView(game, apiImplDeclareWarEmptyTopology, 'gp1');
