// Shared diplomatic-minor API impl suggestion fixtures (Refs #3949 wave 3,
// #3971 wave 4).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

import '../common/game_graphs.dart';

const diplomaticMinorApiImplTopology = MapTopology(nodes: [], edges: []);

Game diplomaticMinorApiImplUnknownFactionGame() => TestFixtures.minimalGame(
  players: const [Player(id: 'gp1', displayName: 'A', isHuman: false)],
  minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
);

Game _diplomaticMinorVisibleMinorGame({
  required List<Player> players,
  List<DiplomacyRelation> diplomacyRelations = const [],
}) => ordersOwRegionGame(
  turnNumber: 1,
  players: players,
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
  diplomacyRelations: diplomacyRelations,
);

Game diplomaticMinorApiImplEstablishOvertureGame() =>
    _diplomaticMinorVisibleMinorGame(
      players: [
        const Player(id: 'gp1', displayName: 'A', isHuman: false).copyWith(
          treasury: 600,
          techUnlocked: const {kTechIdDiplomaticExpertise: true},
        ),
      ],
    );

Game diplomaticMinorApiImplNoDiplomaticExpertiseGame() =>
    _diplomaticMinorVisibleMinorGame(
      players: [
        const Player(
          id: 'gp1',
          displayName: 'A',
          isHuman: false,
        ).copyWith(treasury: 600, techUnlocked: const <String, bool>{}),
      ],
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'minor1',
          state: RelationState.atPeace,
          level: RelationLevel.neutral,
        ),
      ],
    );

Game diplomaticMinorApiImplJoinEmpireDeclareWarGame() => ordersTwoGpEmptyGame(
  players: [
    const Player(
      id: 'gp1',
      displayName: 'A',
      isHuman: false,
    ).copyWith(treasury: 5000),
  ],
  minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
  diplomacyRelations: const [
    DiplomacyRelation(
      factionId1: 'gp1',
      factionId2: 'minor1',
      state: RelationState.atPeace,
      level: RelationLevel.neutral,
    ),
  ],
  overtureStates: const [
    OvertureState(
      gpId: 'gp1',
      targetId: 'minor1',
      stage: OvertureStage.joinEmpire,
      sinceTurn: 0,
    ),
  ],
);

PlayerView diplomaticMinorApiImplViewFor(Game game) =>
    buildPlayerView(game, diplomaticMinorApiImplTopology, 'gp1');
