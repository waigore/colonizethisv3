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
  final army = _armyById(armies, armyId);
  if (army == null) return worldState;
  final unitsByRegion = worldState.mutableUnitListsByRegion();
  final relocated = _relocateArmyRegiments(
    regimentUnitIds: army.regimentUnitIds,
    owUnits: unitsByRegion[kRegionOldWorld]!,
    nwUnits: unitsByRegion[kRegionNewWorld]!,
    destinationProvinceId: destinationProvinceId,
    destinationRegionId: regionId,
  );
  return _worldStateWithUpdatedArmyAndUnits(
    worldState,
    armies,
    relocated.owUnits,
    relocated.nwUnits,
  );
}

({List<Unit> owUnits, List<Unit> nwUnits}) _relocateArmyRegiments({
  required List<String> regimentUnitIds,
  required List<Unit> owUnits,
  required List<Unit> nwUnits,
  required String destinationProvinceId,
  required String destinationRegionId,
}) {
  var lists = (owUnits: owUnits, nwUnits: nwUnits);
  for (final rid in regimentUnitIds) {
    final updated = _moveRegimentToProvince(
      owUnits: lists.owUnits,
      nwUnits: lists.nwUnits,
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
  return regionId == kRegionOldWorld ? owUnits : nwUnits;
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

/// First matching army by id. Single-pass scan; avoids `.where(...).toList()`
/// allocation on migration paths (Refs #2394, SPEC/program/turn-resolution.md).
Army? _armyById(List<Army> armies, String armyId) {
  for (final a in armies) {
    if (a.id == armyId) return a;
  }
  return null;
}

({List<Unit> owUnits, List<Unit> nwUnits}) _moveRegimentToProvince({
  required List<Unit> owUnits,
  required List<Unit> nwUnits,
  required String regimentUnitId,
  required String destinationProvinceId,
  required String destinationRegionId,
}) {
  final indices = _regimentIndices(owUnits, nwUnits, regimentUnitId);
  if (_bothMissing(indices)) return (owUnits: owUnits, nwUnits: nwUnits);

  final inOldWorld = _isOldWorldIndex(indices.owIdx);
  final sourceRegion = _sourceRegionForIndex(inOldWorld);
  if (sourceRegion == destinationRegionId) {
    return _relocateRegimentInSameRegion(
      owUnits: owUnits,
      nwUnits: nwUnits,
      regimentUnitId: regimentUnitId,
      destinationProvinceId: destinationProvinceId,
      inOldWorld: inOldWorld,
    );
  }
  return _relocateRegimentAcrossRegions(
    owUnits: owUnits,
    nwUnits: nwUnits,
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

({List<Unit> owUnits, List<Unit> nwUnits}) _relocateRegimentInSameRegion({
  required List<Unit> owUnits,
  required List<Unit> nwUnits,
  required String regimentUnitId,
  required String destinationProvinceId,
  required bool inOldWorld,
}) {
  if (inOldWorld) {
    return _relocateRegimentInOldWorld(
      owUnits,
      nwUnits,
      regimentUnitId,
      destinationProvinceId,
    );
  }
  return _relocateRegimentInNewWorld(
    owUnits,
    nwUnits,
    regimentUnitId,
    destinationProvinceId,
  );
}

({List<Unit> owUnits, List<Unit> nwUnits}) _relocateRegimentInOldWorld(
  List<Unit> owUnits,
  List<Unit> nwUnits,
  String regimentUnitId,
  String destinationProvinceId,
) => (
  owUnits: owUnits
      .map(
        (u) => u.id == regimentUnitId
            ? u.copyWith(locationProvinceId: destinationProvinceId)
            : u,
      )
      .toList(),
  nwUnits: nwUnits,
);

({List<Unit> owUnits, List<Unit> nwUnits}) _relocateRegimentInNewWorld(
  List<Unit> owUnits,
  List<Unit> nwUnits,
  String regimentUnitId,
  String destinationProvinceId,
) => (
  owUnits: owUnits,
  nwUnits: nwUnits
      .map(
        (u) => u.id == regimentUnitId
            ? u.copyWith(locationProvinceId: destinationProvinceId)
            : u,
      )
      .toList(),
);

({List<Unit> owUnits, List<Unit> nwUnits}) _relocateRegimentAcrossRegions({
  required List<Unit> owUnits,
  required List<Unit> nwUnits,
  required int owIdx,
  required int nwIdx,
  required String destinationProvinceId,
  required String destinationRegionId,
  required bool inOldWorld,
}) {
  final unit = inOldWorld ? owUnits.removeAt(owIdx) : nwUnits.removeAt(nwIdx);
  final moved = unit.copyWith(locationProvinceId: destinationProvinceId);
  if (destinationRegionId == kRegionOldWorld) {
    return (owUnits: [...owUnits, moved], nwUnits: nwUnits);
  }
  return (owUnits: owUnits, nwUnits: [...nwUnits, moved]);
}
