library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetExplore, kWorkTargetProspect;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:colonizethis_app_e2e_support/e2e_test_shared.dart';

const String human = 'gp1';

const TurnState _orderingTurn = TurnState(
  phase: TurnPhase.orders,
  turnNumber: 1,
);

const MapTopology emptyTopology = MapTopology();

const Orders emptyOrders = Orders();

const RegionData _emptyRegion = RegionData();

Unit makeExplorerUnit({
  required String id,
  required String provinceId,
  String? tileKey,
}) => Unit(
  id: id,
  type: kUnitTypeExplorer,
  ownerId: human,
  locationProvinceId: provinceId,
  tileKey: tileKey,
);

WorldState world({
  RegionData oldWorld = _emptyRegion,
  RegionData newWorld = _emptyRegion,
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
}) => WorldState(
  turnState: _orderingTurn,
  oldWorld: oldWorld,
  newWorld: newWorld,
  playerVisibilityByTile: playerVisibilityByTile,
);

Game _game({
  RegionData oldWorld = _emptyRegion,
  RegionData newWorld = _emptyRegion,
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
}) => Game(
  id: 'g1',
  worldState: world(
    oldWorld: oldWorld,
    newWorld: newWorld,
    playerVisibilityByTile: playerVisibilityByTile,
  ),
  players: const [Player(id: human, displayName: 'You', isHuman: true)],
);

CtE2eNavalPanelSnapshot navalSnapshot({
  RegionData oldWorld = _emptyRegion,
  RegionData newWorld = _emptyRegion,
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
  Orders draftOrders = emptyOrders,
}) => CtE2eNavalPanelSnapshot(
  game: _game(
    oldWorld: oldWorld,
    newWorld: newWorld,
    playerVisibilityByTile: playerVisibilityByTile,
  ),
  humanPlayerId: human,
  topology: emptyTopology,
  draftOrders: draftOrders,
);

CtE2eCivilianPanelSnapshot civilianSnapshot({
  Map<String, List<String>> availableWorkTargets = const {},
}) => CtE2eCivilianPanelSnapshot(
  game: _game(),
  humanPlayerId: human,
  currentOrders: emptyOrders,
  availableWorkTargets: availableWorkTargets,
);


