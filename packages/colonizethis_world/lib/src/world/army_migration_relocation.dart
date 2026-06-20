part of 'army_migration.dart';

// Army station retargeting and per-regiment relocation across regions
// (Refs #3290 Phase-0 file-split). Behaviour-preserving move: same library
// scope as `army_migration.dart`, so imports, constants ([kRegionOldWorld],
// [kRegionNewWorld]), and shared helpers ([_regionIdForProvinceInWorld]) are
// unchanged.

/// Updates army [stationedProvinceId] and all regiment locations for [armyId].
WorldState updateArmyStation(
  WorldState worldState,
  String armyId,
  String destinationProvinceId,
) {
  final regionId = _regionIdForProvinceInWorld(
    worldState,
    destinationProvinceId,
  );
  final armies = _retargetArmyStation(
    worldState.armies,
    armyId,
    destinationProvinceId,
    regionId,
  );
  final army = firstArmyById(armies, armyId);
  if (army == null) return worldState;
  final unitsByRegion = worldState.mutableUnitListsByRegion();
  final relocated = _relocateArmyRegiments(
    regimentUnitIds: army.regimentUnitIds,
    ow: unitsByRegion[kRegionOldWorld]!,
    nw: unitsByRegion[kRegionNewWorld]!,
    destinationProvinceId: destinationProvinceId,
    destinationRegionId: regionId,
  );
  return _worldStateWithUpdatedArmyAndUnits(
    worldState,
    armies,
    relocated.ow,
    relocated.nw,
  );
}

RegionUnitLists _relocateArmyRegiments({
  required List<String> regimentUnitIds,
  required List<Unit> ow,
  required List<Unit> nw,
  required String destinationProvinceId,
  required String destinationRegionId,
}) {
  var lists = (ow: ow, nw: nw);
  for (final rid in regimentUnitIds) {
    final updated = _moveRegimentToProvince(
      ow: lists.ow,
      nw: lists.nw,
      regimentUnitId: rid,
      destinationProvinceId: destinationProvinceId,
      destinationRegionId: destinationRegionId,
    );
    lists = updated;
  }
  return lists;
}

WorldState _worldStateWithUpdatedArmyAndUnits(
  WorldState worldState,
  List<Army> armies,
  List<Unit> owUnits,
  List<Unit> nwUnits,
) => worldState.copyWith(armies: armies).mapBothRegionUnits((regionId, _) {
  return (ow: owUnits, nw: nwUnits).unitListForRegion(regionId);
});

List<Army> _retargetArmyStation(
  List<Army> armies,
  String armyId,
  String destinationProvinceId,
  String regionId,
) => armies
    .map(
      (a) => a.id != armyId
          ? a
          : a.copyWith(
              stationedProvinceId: destinationProvinceId,
              regionId: regionId,
            ),
    )
    .toList();

RegionUnitLists _moveRegimentToProvince({
  required List<Unit> ow,
  required List<Unit> nw,
  required String regimentUnitId,
  required String destinationProvinceId,
  required String destinationRegionId,
}) {
  final indices = _regimentIndices(ow, nw, regimentUnitId);
  if (_bothMissing(indices)) return (ow: ow, nw: nw);

  final inOldWorld = _isOldWorldIndex(indices.owIdx);
  final sourceRegion = _sourceRegionForIndex(inOldWorld);
  if (sourceRegion == destinationRegionId) {
    return _relocateRegimentInSameRegion(
      ow: ow,
      nw: nw,
      regimentUnitId: regimentUnitId,
      destinationProvinceId: destinationProvinceId,
      inOldWorld: inOldWorld,
    );
  }
  return _relocateRegimentAcrossRegions(
    ow: ow,
    nw: nw,
    owIdx: indices.owIdx,
    nwIdx: indices.nwIdx,
    destinationProvinceId: destinationProvinceId,
    destinationRegionId: destinationRegionId,
    inOldWorld: inOldWorld,
  );
}

bool _bothMissing(({int owIdx, int nwIdx}) indices) =>
    indices.owIdx < 0 && indices.nwIdx < 0;

({int owIdx, int nwIdx}) _regimentIndices(
  List<Unit> owUnits,
  List<Unit> nwUnits,
  String regimentUnitId,
) {
  // Old-world list is authoritative when the same id appears in both (invalid
  // state); skip scanning new world once a match is found (Refs #2394).
  for (var i = 0; i < owUnits.length; i++) {
    if (owUnits[i].id == regimentUnitId) {
      return (owIdx: i, nwIdx: -1);
    }
  }
  for (var i = 0; i < nwUnits.length; i++) {
    if (nwUnits[i].id == regimentUnitId) {
      return (owIdx: -1, nwIdx: i);
    }
  }
  return (owIdx: -1, nwIdx: -1);
}

bool _isOldWorldIndex(int owIdx) => owIdx >= 0;
String _sourceRegionForIndex(bool inOldWorld) =>
    inOldWorld ? kRegionOldWorld : kRegionNewWorld;

RegionUnitLists _relocateRegimentInSameRegion({
  required List<Unit> ow,
  required List<Unit> nw,
  required String regimentUnitId,
  required String destinationProvinceId,
  required bool inOldWorld,
}) {
  if (inOldWorld) {
    return _relocateRegimentInOldWorld(
      ow,
      nw,
      regimentUnitId,
      destinationProvinceId,
    );
  }
  return _relocateRegimentInNewWorld(
    ow,
    nw,
    regimentUnitId,
    destinationProvinceId,
  );
}

RegionUnitLists _relocateRegimentInOldWorld(
  List<Unit> ow,
  List<Unit> nw,
  String regimentUnitId,
  String destinationProvinceId,
) => (
  ow: ow
      .map(
        (u) => u.id == regimentUnitId
            ? u.copyWith(locationProvinceId: destinationProvinceId)
            : u,
      )
      .toList(),
  nw: nw,
);

RegionUnitLists _relocateRegimentInNewWorld(
  List<Unit> ow,
  List<Unit> nw,
  String regimentUnitId,
  String destinationProvinceId,
) => (
  ow: ow,
  nw: nw
      .map(
        (u) => u.id == regimentUnitId
            ? u.copyWith(locationProvinceId: destinationProvinceId)
            : u,
      )
      .toList(),
);

RegionUnitLists _relocateRegimentAcrossRegions({
  required List<Unit> ow,
  required List<Unit> nw,
  required int owIdx,
  required int nwIdx,
  required String destinationProvinceId,
  required String destinationRegionId,
  required bool inOldWorld,
}) {
  final unit = inOldWorld ? ow.removeAt(owIdx) : nw.removeAt(nwIdx);
  final moved = unit.copyWith(locationProvinceId: destinationProvinceId);
  if (destinationRegionId == kRegionOldWorld) {
    return (ow: [...ow, moved], nw: nw);
  }
  return (ow: ow, nw: [...nw, moved]);
}
