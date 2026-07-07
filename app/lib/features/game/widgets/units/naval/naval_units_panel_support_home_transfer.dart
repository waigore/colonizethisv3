/// Home-fleet transfer eligibility and dialog. SPEC/ui/naval-units-panel.md.

part of 'naval_units_panel.dart';

extension _NavalUnitsPanelHomeTransfer on _NavalUnitsPanelState {
  ({FleetRow home, FleetRow source})? _homeTransferRows(
    List<FleetRow> flat,
    Set<String> selectedIds,
  ) {
    if (selectedIds.length != 2) return null;
    FleetRow? home;
    FleetRow? source;
    for (final row in flat) {
      final id = _selectionFleetId(row);
      if (!selectedIds.contains(id)) continue;
      if (row.isHomeFleet) {
        home = row;
      } else {
        source = row;
      }
    }
    if (home == null || source == null) return null;
    return (home: home, source: source);
  }

  String? _humanCapitalProvinceId() {
    for (final p in widget.game.players) {
      if (p.id == widget.humanPlayerId) return p.capitalProvinceId;
    }
    return null;
  }

  bool _provinceMatchesCapital(String provinceId, String capitalProvinceId) {
    if (provinceId == capitalProvinceId) return true;
    final capRegionId = ProvinceId.regionIdFrom(capitalProvinceId);
    final capLocalId = ProvinceId.localIdFrom(capitalProvinceId);
    return provinceId == capLocalId || provinceId == '$capRegionId|$capLocalId';
  }

  bool _seaZoneAdjacentToCapital({
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

  bool _isEligibleHomeTransferSource(FleetRow sourceRow) {
    final sourceFleet = _fleetForRow(sourceRow);
    final capitalProvinceId = _humanCapitalProvinceId();
    if (sourceFleet == null || capitalProvinceId == null) return false;
    if (sourceFleet.ownerId != widget.humanPlayerId) return false;
    if (!sourceFleet.isAtSea) {
      final inPortId = sourceFleet.inPortAtProvinceId;
      if (inPortId == null) return false;
      return _provinceMatchesCapital(inPortId, capitalProvinceId);
    }
    final seaZoneId = sourceFleet.seaZoneId;
    if (seaZoneId == null || seaZoneId.isEmpty) return false;
    return _seaZoneAdjacentToCapital(
      sourceSeaZoneId: seaZoneId,
      sourceRegionId: sourceFleet.regionId,
      capitalProvinceId: capitalProvinceId,
    );
  }

  void _openTransferToHomeDialog({
    required FleetRow homeRow,
    required FleetRow sourceRow,
  }) {
    final homeFleet = _fleetForRow(homeRow);
    final sourceFleet = _fleetForRow(sourceRow);
    if (homeFleet == null || sourceFleet == null) return;
    showDialog<void>(
      context: context,
      builder: (_) => TransferToHomeFleetDialog(
        sourceFleet: sourceFleet,
        homeFleet: homeFleet,
        game: widget.game,
        humanPlayerId: widget.humanPlayerId,
        bus: widget.bus,
      ),
    );
  }
}
