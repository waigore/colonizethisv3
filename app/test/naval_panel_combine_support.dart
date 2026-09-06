// Naval combine fleet helpers and autoclose tables (Refs #4352 Slice D).
// Outcome typedefs/builders: naval_panel_combine_outcome_helpers.dart.

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'naval_units_panel_test_scenarios.dart';

typedef NavalPanelPortShipSpec = ({String id, String shipId, String typeId});

Fleet navalPanelPortShipFleet({
  required String id,
  required String humanId,
  required String port,
  required String shipId,
  String typeId = 'carrack',
}) => Fleet(
  id: id,
  ownerId: humanId,
  regionId: 'oldWorld',
  inPortAtProvinceId: port,
  ships: [ShipInstance(id: shipId, typeId: typeId)],
);

Fleet navalPanelSeaShipFleet({
  required String id,
  required String humanId,
  required String seaZoneId,
  required String shipId,
  String typeId = 'carrack',
}) => Fleet(
  id: id,
  ownerId: humanId,
  regionId: 'oldWorld',
  seaZoneId: seaZoneId,
  ships: [ShipInstance(id: shipId, typeId: typeId)],
);

Game buildNavalPanelMergePortFleetsFromSpecs({
  required String humanId,
  required String gameId,
  required String displayName,
  required List<NavalPanelPortShipSpec> fleets,
  int? nextShipInstanceSeq,
}) => buildNavalPanelCapitalMergePortFleetsGame(
  humanId: humanId,
  gameId: gameId,
  displayName: displayName,
  includeMergePortTileKeys: false,
  nextShipInstanceSeq: nextShipInstanceSeq ?? fleets.length + 1,
  fleets: [
    for (final f in fleets)
      navalPanelPortShipFleet(
        id: f.id,
        humanId: humanId,
        port: kNavalPanelMergePort,
        shipId: f.shipId,
        typeId: f.typeId,
      ),
  ],
);

Fleet navalPanelPortFleetAtMergePort(
  String id,
  String humanId,
  String shipId,
  String typeId, {
  FleetMission mission = FleetMission.none,
}) => Fleet(
  id: id,
  ownerId: humanId,
  regionId: 'oldWorld',
  inPortAtProvinceId: kNavalPanelMergePort,
  ships: [ShipInstance(id: shipId, typeId: typeId)],
  mission: mission,
);

typedef NavalPanelAutocloseCase = ({
  String humanId,
  String gameId,
  String displayName,
  String? locationScopeKey,
  MapTopology? topology,
  bool removeFleetOnNextFrame,
  bool emitMove,
  bool expectFleetRow,
  int closeCount,
});

List<NavalPanelAutocloseCase> navalPanelAutocloseCases() => [
  (
    humanId: 'gp_scope_autoclose_yes',
    gameId: 'g_scope_autoclose_yes',
    displayName: 'Scoped AutoClose',
    locationScopeKey: 'sea:oldWorld|s1',
    topology: null,
    removeFleetOnNextFrame: false,
    emitMove: true,
    expectFleetRow: true,
    closeCount: 1,
  ),
  (
    humanId: 'gp_scope_autoclose_no_full',
    gameId: 'g_scope_autoclose_no_full',
    displayName: 'Full List',
    locationScopeKey: null,
    topology: null,
    removeFleetOnNextFrame: false,
    emitMove: true,
    expectFleetRow: false,
    closeCount: 0,
  ),
  (
    humanId: 'gp_scope_autoclose_no_external',
    gameId: 'g_scope_autoclose_no_external',
    displayName: 'Scoped External',
    locationScopeKey: 'sea:oldWorld|s1',
    topology: const MapTopology(),
    removeFleetOnNextFrame: true,
    emitMove: false,
    expectFleetRow: false,
    closeCount: 0,
  ),
];
