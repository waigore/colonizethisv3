// Shared `CtE2eNavalPanelSnapshot` fixtures for the ct-snapshot predicate
// suites (#4344 Slice C densify): `e2e_player_has_any_new_world_fogged_or_
// better_from_ct_snapshot_test.dart` and
// `e2e_non_home_human_fleet_in_new_world_from_ct_snapshot_test.dart`
// previously each declared near-identical `Game` / `WorldState` /
// `CtE2eNavalPanelSnapshot` builders. This file unifies both call shapes
// behind one set of optional-field builders.
library;

import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TopologyNode, TopologyNodeType;
import 'package:colonizethis_models/colonizethis_models.dart';

const String ctNavalSnapshotHuman = 'gp1';
const String ctNavalSnapshotOtherGp = 'gp2';

const TurnState ctNavalSnapshotOrderingTurn = TurnState(
  phase: TurnPhase.orders,
  turnNumber: 1,
);

const RegionData ctNavalSnapshotEmptyRegion = RegionData();
const Orders ctNavalSnapshotEmptyOrders = Orders();
const MapTopology ctNavalSnapshotEmptyTopology = MapTopology();

Province ctNavalSnapshotNwProvince(String localId) =>
    Province(id: ProvinceId.full('newWorld', localId), regionId: 'newWorld');

Province ctNavalSnapshotOwProvince(String localId) =>
    Province(id: ProvinceId.full('oldWorld', localId), regionId: 'oldWorld');

MapTopology ctNavalSnapshotTopologyWithSeaZone({
  required String seaId,
  required String regionId,
}) => MapTopology(
  nodes: [
    TopologyNode(id: seaId, regionId: regionId, type: TopologyNodeType.seaZone),
  ],
);

/// Home fleet fixture; `id` follows the `fleet_<humanPlayerId>` contract the
/// predicates under test skip by id.
Fleet ctNavalSnapshotHomeFleet({
  String regionId = 'oldWorld',
  String? inPortAtProvinceId = 'oldWorld|capital',
}) => Fleet(
  id: 'fleet_$ctNavalSnapshotHuman',
  ownerId: ctNavalSnapshotHuman,
  regionId: regionId,
  inPortAtProvinceId: inPortAtProvinceId,
);

WorldState ctNavalSnapshotWorld({
  RegionData oldWorld = ctNavalSnapshotEmptyRegion,
  RegionData newWorld = ctNavalSnapshotEmptyRegion,
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
  List<Fleet> fleets = const [],
}) => WorldState(
  turnState: ctNavalSnapshotOrderingTurn,
  oldWorld: oldWorld,
  newWorld: newWorld,
  playerVisibilityByTile: playerVisibilityByTile,
  fleets: fleets,
);

Game ctNavalSnapshotGame({
  RegionData oldWorld = ctNavalSnapshotEmptyRegion,
  RegionData newWorld = ctNavalSnapshotEmptyRegion,
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
  List<Fleet> fleets = const [],
}) => Game(
  id: 'g1',
  worldState: ctNavalSnapshotWorld(
    oldWorld: oldWorld,
    newWorld: newWorld,
    playerVisibilityByTile: playerVisibilityByTile,
    fleets: fleets,
  ),
  players: const [
    Player(id: ctNavalSnapshotHuman, displayName: 'You', isHuman: true),
  ],
);

CtE2eNavalPanelSnapshot ctNavalSnapshot({
  RegionData oldWorld = ctNavalSnapshotEmptyRegion,
  RegionData newWorld = ctNavalSnapshotEmptyRegion,
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
  List<Fleet> fleets = const [],
  MapTopology topology = ctNavalSnapshotEmptyTopology,
}) => CtE2eNavalPanelSnapshot(
  game: ctNavalSnapshotGame(
    oldWorld: oldWorld,
    newWorld: newWorld,
    playerVisibilityByTile: playerVisibilityByTile,
    fleets: fleets,
  ),
  humanPlayerId: ctNavalSnapshotHuman,
  topology: topology,
  draftOrders: ctNavalSnapshotEmptyOrders,
);
