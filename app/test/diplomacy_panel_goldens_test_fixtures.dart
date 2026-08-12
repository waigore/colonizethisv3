// Golden fixtures and pump helpers for diplomacy panel visual acceptance tests.
// Used by `diplomacy_panel_goldens_test.dart` (Refs #4305).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_panel.dart';

import 'diplomacy_panel_test_support.dart';
import 'golden_capture_harness.dart';

const MapTopology diplomacyPanelGoldenEmptyTopology = MapTopology(
  nodes: [],
  edges: [],
);

const Player diplomacyPanelGoldenSoloGp = Player(
  id: 'gp1',
  displayName: 'Solo',
  isHuman: true,
);
const Player diplomacyPanelGoldenAlbion = Player(
  id: 'gp1',
  displayName: 'Albion',
  isHuman: true,
);
const Player diplomacyPanelGoldenCastile = Player(
  id: 'gp2',
  displayName: 'Castile',
  isHuman: false,
);
const List<Player> diplomacyPanelGoldenAlbionCastile = [
  diplomacyPanelGoldenAlbion,
  diplomacyPanelGoldenCastile,
];

Province diplomacyPanelGoldenProvince(
  String regionId,
  String localId,
  String displayName,
  String ownerId,
) =>
    Province(
      id: '$regionId|$localId',
      regionId: regionId,
      displayName: displayName,
      ownerId: ownerId,
    );

WorldState diplomacyPanelGoldenWorld({
  required int turnNumber,
  List<Province> oldWorldProvinces = const [],
  List<Province> newWorldProvinces = const [],
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
  Map<String, String> purchasedTilesByTileKey = const {},
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince =
      const {},
}) {
  return WorldState(
    turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
    oldWorld: RegionData(provinces: oldWorldProvinces, units: const []),
    newWorld: newWorldProvinces.isEmpty
        ? const RegionData()
        : RegionData(provinces: newWorldProvinces, units: const []),
    playerVisibilityByTile: playerVisibilityByTile,
    playerProspectedTiles: const {},
    purchasedTilesByTileKey: purchasedTilesByTileKey,
    tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
  );
}

Game diplomacyPanelGoldenGame({
  required String id,
  required WorldState world,
  List<Player> players = const [diplomacyPanelGoldenAlbion],
  List<DiplomacyRelation> diplomacyRelations = const [],
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
  List<OvertureState> overtureStates = const [],
  List<ColonyState> colonyStates = const [],
  List<BoycottState> boycottStates = const [],
  List<SubsidyState> subsidyStates = const [],
}) {
  return Game(
    id: id,
    worldState: world,
    players: players,
    tribes: tribes,
    minorNations: minorNations,
    diplomacyRelations: diplomacyRelations,
    overtureStates: overtureStates,
    colonyStates: colonyStates,
    boycottStates: boycottStates,
    subsidyStates: subsidyStates,
  );
}

WorldState diplomacyPanelGoldenHomeRivalWorld({required int turnNumber}) =>
    diplomacyPanelGoldenWorld(
      turnNumber: turnNumber,
      oldWorldProvinces: [
        diplomacyPanelGoldenProvince('oldWorld', 'p1', 'Home', 'gp1'),
        diplomacyPanelGoldenProvince('oldWorld', 'p2', 'Rival', 'gp2'),
      ],
    );

WorldState diplomacyPanelGoldenHomeTribeWorld({
  required int turnNumber,
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
}) =>
    diplomacyPanelGoldenWorld(
      turnNumber: turnNumber,
      oldWorldProvinces: [
        diplomacyPanelGoldenProvince('oldWorld', 'p1', 'Home', 'gp1'),
      ],
      newWorldProvinces: [
        diplomacyPanelGoldenProvince('newWorld', 't1prov', 'Tribe Land', 't1'),
      ],
      playerVisibilityByTile: playerVisibilityByTile,
    );

Game diplomacyPanelGoldenEmptyStateGame() => diplomacyPanelGoldenGame(
  id: 'diplo-golden-empty',
  world: diplomacyPanelGoldenWorld(
    turnNumber: 0,
    oldWorldProvinces: [
      diplomacyPanelGoldenProvince('oldWorld', 'p1', 'P1', 'gp1'),
    ],
  ),
  players: const [diplomacyPanelGoldenSoloGp],
);

Game diplomacyPanelGoldenGreatPowerRowGame() => diplomacyPanelGoldenGame(
  id: 'diplo-golden-gp',
  world: diplomacyPanelGoldenHomeRivalWorld(turnNumber: 4),
  players: diplomacyPanelGoldenAlbionCastile,
  diplomacyRelations: const [
    DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2'),
  ],
);

Game diplomacyPanelGoldenAlliedGreatPowerRowGame() => diplomacyPanelGoldenGame(
  id: 'diplo-golden-gp-alliance',
  world: diplomacyPanelGoldenHomeRivalWorld(turnNumber: 4),
  players: diplomacyPanelGoldenAlbionCastile,
  diplomacyRelations: const [
    DiplomacyRelation(
      factionId1: 'gp1',
      factionId2: 'gp2',
      score: 90,
      formalAlliance: true,
    ),
  ],
);

Game diplomacyPanelGoldenTribeRowGame() => diplomacyPanelGoldenGame(
  id: 'diplo-golden-tribe',
  world: diplomacyPanelGoldenHomeTribeWorld(
    turnNumber: 3,
    playerVisibilityByTile: const {
      'gp1': {'newWorld|t1prov|0|0': 'fullyVisible'},
    },
  ),
  tribes: const [Tribe(id: 't1', displayName: 'Powhatan')],
);

Game diplomacyPanelGoldenColonyTribeRowGame() => diplomacyPanelGoldenGame(
  id: 'diplo-golden-colony-tribe',
  world: diplomacyPanelGoldenHomeTribeWorld(turnNumber: 6),
  players: diplomacyPanelGoldenAlbionCastile,
  tribes: const [Tribe(id: 't1', displayName: 'Powhatan')],
  diplomacyRelations: const [
    DiplomacyRelation(factionId1: 'gp1', factionId2: 't1', score: 60),
    DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2', score: 40),
  ],
  overtureStates: const [
    OvertureState(gpId: 'gp1', targetId: 't1', stage: OvertureStage.embassy),
  ],
  colonyStates: const [
    ColonyState(tribeId: 't1', colonyOfGpId: 'gp1', sinceTurn: 5),
  ],
  boycottStates: const [
    BoycottState(gpId: 'gp1', targetGpId: 'gp2', sinceTurn: 6),
  ],
);

Game diplomacyPanelGoldenSubsidizedMinorRowGame() {
  const nw = 'newWorld';
  const minorProvinceId = '$nw|m1prov';
  const tileA = '$minorProvinceId|0|0';
  const tileB = '$minorProvinceId|1|0';
  return diplomacyPanelGoldenGame(
    id: 'diplo-golden-subsidized-minor',
    world: diplomacyPanelGoldenWorld(
      turnNumber: 8,
      oldWorldProvinces: [
        diplomacyPanelGoldenProvince('oldWorld', 'p1', 'Home', 'gp1'),
      ],
      newWorldProvinces: [
        diplomacyPanelGoldenProvince(nw, 'm1prov', 'Bavaria Coast', 'm1'),
      ],
      purchasedTilesByTileKey: const {tileA: 'gp1', tileB: 'gp1'},
      tileKeysByRegionAndProvince: const {
        nw: {
          minorProvinceId: [tileA, tileB],
        },
      },
    ),
    minorNations: const [MinorNation(id: 'm1', displayName: 'Bavaria')],
    diplomacyRelations: const [
      DiplomacyRelation(factionId1: 'gp1', factionId2: 'm1', score: 80),
    ],
    overtureStates: const [
      OvertureState(gpId: 'gp1', targetId: 'm1', stage: OvertureStage.embassy),
    ],
    subsidyStates: const [
      SubsidyState(payerId: 'gp1', targetId: 'm1', percent: 10),
    ],
  );
}

Widget diplomacyPanelGoldenHost({
  required Game game,
  required Key boundaryKey,
  MapTopology topology = diplomacyPanelGoldenEmptyTopology,
  double width = 460,
  double height = 1000,
}) {
  return wrapGoldenBoundary(
    boundaryKey: boundaryKey,
    child: SizedBox(
      width: width,
      height: height,
      child: DiplomacyPanel(
        game: game,
        humanPlayerId: 'gp1',
        topology: topology,
        currentOrders: const Orders(),
        bus: AppEventBus.create(),
      ),
    ),
  );
}

Future<void> pumpDiplomacyPanelGolden(
  WidgetTester tester, {
  required Game game,
  required Key boundaryKey,
  Size surface = const Size(600, 1100),
  double width = 460,
  double height = 1000,
}) async {
  await configureGoldenSurface(tester, size: surface);
  await tester.pumpWidget(
    diplomacyPanelGoldenHost(
      game: game,
      boundaryKey: boundaryKey,
      width: width,
      height: height,
    ),
  );
  await pumpDiplomacyPanelBuilt(tester);
}

Future<void> runDiplomacyPanelGolden(
  WidgetTester tester, {
  required Game game,
  required String keyId,
  required String golden,
  required void Function(WidgetTester tester) pin,
  Size surface = const Size(600, 1100),
  double width = 460,
  double height = 1000,
}) async {
  final boundaryKey = ValueKey<String>(keyId);
  await pumpDiplomacyPanelGolden(
    tester,
    game: game,
    boundaryKey: boundaryKey,
    surface: surface,
    width: width,
    height: height,
  );
  pin(tester);
  await expectLater(
    find.byKey(boundaryKey),
    matchesGoldenFile(golden),
  );
}
