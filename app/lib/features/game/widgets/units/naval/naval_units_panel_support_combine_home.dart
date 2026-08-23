import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show GamePlayerLookup, homeFleetIdFor;

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../panels/tree_builders/naval_tree_builder.dart';
import '../../unit_orders/transfer_to_home_fleet_dialog.dart';
import '../shared/base_units_panel.dart';
import 'naval_units_panel.dart';
import 'naval_units_panel_state_base.dart';

mixin NavalUnitsPanelCombineHome
    on BaseUnitsPanelState<NavalUnitsPanel>, NavalUnitsPanelStateBase {
  String selectionFleetId(FleetRow row) {
    if (row.isHomeFleet) return homeFleetIdFor(widget.humanPlayerId);
    return row.fleetId;
  }

  Fleet? fleetForRow(FleetRow row) {
    final id = selectionFleetId(row);
    final found = widget.game.fleetById(id);
    if (found != null) return found;
    if (row.isHomeFleet) {
      final portId = row.inPortAtProvinceId;
      if (portId == null) return null;
      return Fleet(
        id: id,
        ownerId: widget.humanPlayerId,
        regionId: row.regionId,
        inPortAtProvinceId: portId,
        ships: const [],
        mission: FleetMission.none,
      );
    }
    return null;
  }

  String? humanCapitalProvinceId() =>
      widget.game.playerById(widget.humanPlayerId)?.capitalProvinceId;

  bool provinceMatchesCapital(String provinceId, String capitalProvinceId) {
    if (provinceId == capitalProvinceId) return true;
    final capRegionId = ProvinceId.regionIdFrom(capitalProvinceId);
    final capLocalId = ProvinceId.localIdFrom(capitalProvinceId);
    return provinceId == capLocalId || provinceId == '$capRegionId|$capLocalId';
  }

  bool seaZoneAdjacentToCapital({
    required String sourceSeaZoneId,
    required String sourceRegionId,
    required String capitalProvinceId,
  }) {
    final capRegionId = ProvinceId.regionIdFrom(capitalProvinceId);
    final capLocalId = ProvinceId.localIdFrom(capitalProvinceId);
    final sourceSeaLocal = prefixedIdLocalSegment(sourceSeaZoneId);
    final sourceSeaPrefixed = prefixedIdHasDelimiter(sourceSeaZoneId)
        ? sourceSeaZoneId
        : '$sourceRegionId|$sourceSeaZoneId';
    final sourceSeaCandidates = <String>{
      sourceSeaZoneId,
      sourceSeaLocal,
      sourceSeaPrefixed,
    };
    final capitalCandidates = <String>{
      capitalProvinceId,
      capLocalId,
      '$capRegionId|$capLocalId',
    };
    for (final edge in widget.topology.edges) {
      final a = edge.id1;
      final b = edge.id2;
      final aIsSea = sourceSeaCandidates.contains(a);
      final bIsSea = sourceSeaCandidates.contains(b);
      final aIsCap = capitalCandidates.contains(a);
      final bIsCap = capitalCandidates.contains(b);
      if ((aIsSea && bIsCap) || (bIsSea && aIsCap)) {
        return true;
      }
    }
    return false;
  }

  bool isEligibleHomeTransferSource(FleetRow sourceRow) {
    final sourceFleet = fleetForRow(sourceRow);
    final capitalProvinceId = humanCapitalProvinceId();
    if (sourceFleet == null || capitalProvinceId == null) return false;
    if (sourceFleet.ownerId != widget.humanPlayerId) return false;
    if (!sourceFleet.isAtSea) {
      final inPortId = sourceFleet.inPortAtProvinceId;
      if (inPortId == null) return false;
      return provinceMatchesCapital(inPortId, capitalProvinceId);
    }
    final seaZoneId = sourceFleet.seaZoneId;
    if (seaZoneId == null || seaZoneId.isEmpty) return false;
    return seaZoneAdjacentToCapital(
      sourceSeaZoneId: seaZoneId,
      sourceRegionId: sourceFleet.regionId,
      capitalProvinceId: capitalProvinceId,
    );
  }

  void openTransferToHomeDialog({
    required FleetRow homeRow,
    required FleetRow sourceRow,
  }) {
    final homeFleet = fleetForRow(homeRow);
    final sourceFleet = fleetForRow(sourceRow);
    if (homeFleet == null || sourceFleet == null) return;
    showDialog<void>(
      context: context,
      builder: (_) => TransferToHomeFleetDialog(
        sourceFleet: sourceFleet,
        homeFleet: homeFleet,
        game: widget.game,
        humanPlayerId: widget.humanPlayerId,
        bus: widget.bus,
        overseasCargoUsed: widget.overseasCargoUsed,
        isCargoUsedReliable: widget.isCargoUsedReliable,
        cargoNotDefined: widget.cargoNotDefined,
      ),
    );
  }
}
