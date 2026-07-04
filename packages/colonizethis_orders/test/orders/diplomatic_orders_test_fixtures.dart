/// Shared GP–Minor diplomatic test games for orders package tests (Refs #3877).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const emptyTopology = MapTopology(nodes: [], edges: []);

/// Default GP treasury for order-engine diplomatic validation tests.
const gpMinorOrderEngineTreasury = 5000;

/// Parameterized GP + Minor Nation fixture used across diplomatic validator,
/// order-engine, and panel-action tests.
Game gpMinorGame({
  RelationState relationState = RelationState.atPeace,
  int relationScore = 50,
  OvertureStage overtureStage = OvertureStage.none,
  int treasury = 0,
  Map<String, bool>? techUnlocked,
  int turnNumber = 0,
  String gameId = 'g1',
  bool includeSecondGp = false,
  bool includeProvinces = false,
  List<OvertureState>? overtureStates,
  String gp1DisplayName = 'GP1',
  String minorDisplayName = 'Minor 1',
}) {
  const ow = 'oldWorld';
  final oldWorld = includeProvinces
      ? RegionData(
          provinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
            Province(id: '$ow|m1', regionId: ow, ownerId: 'minor1'),
          ],
        )
      : const RegionData();

  final players = <Player>[
    Player(
      id: 'gp1',
      displayName: gp1DisplayName,
      isHuman: true,
      treasury: treasury,
      techUnlocked: techUnlocked ?? const {kTechIdDiplomaticExpertise: true},
    ),
    if (includeSecondGp)
      Player(
        id: 'gp2',
        displayName: 'B',
        isHuman: false,
        treasury: 5000,
      ),
  ];

  final diplomacyRelations = includeSecondGp
      ? <DiplomacyRelation>[
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: relationScore,
          ),
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            score: relationScore,
          ),
        ]
      : <DiplomacyRelation>[
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'minor1',
            state: relationState,
            score: relationScore,
          ),
        ];

  final resolvedOvertureStates = overtureStates ??
      [
        OvertureState(
          gpId: 'gp1',
          targetId: 'minor1',
          stage: overtureStage,
          sinceTurn: 0,
        ),
      ];

  return Game(
    id: gameId,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
      oldWorld: oldWorld,
      newWorld: const RegionData(),
    ),
    players: players,
    minorNations: [MinorNation(id: 'minor1', displayName: minorDisplayName)],
    diplomacyRelations: diplomacyRelations,
    overtureStates: resolvedOvertureStates,
  );
}

/// GP + Minor + second GP with provinces for diplomatic panel action tests.
Game gpMinorPanelActionsGame() => gpMinorGame(
      gameId: 'g',
      turnNumber: 1,
      treasury: 5000,
      gp1DisplayName: 'A',
      minorDisplayName: 'Bavaria',
      includeSecondGp: true,
      includeProvinces: true,
      overtureStates: const [],
    );
