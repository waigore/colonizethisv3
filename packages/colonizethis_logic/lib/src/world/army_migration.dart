import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import 'army_ids.dart';

/// Prefixed ids use [ProvinceId.regionIdFrom]; otherwise resolve from [WorldState]
/// (legacy tests and fixtures may use local province ids only).
String _regionIdForProvinceInWorld(WorldState ws, String provinceId) {
  if (ProvinceId.isPrefixed(provinceId)) {
    return ProvinceId.regionIdFrom(provinceId);
  }
  if (ws.oldWorld.provinces.any((p) => p.id == provinceId)) {
    return kRegionOldWorld;
  }
  if (ws.newWorld.provinces.any((p) => p.id == provinceId)) {
    return kRegionNewWorld;
  }
  throw StateError('Province id not found in either region: "$provinceId"');
}

/// Prefixed [Unit.locationProvinceId] uses [ProvinceId.regionIdFrom]; otherwise
/// infer region from which regional unit list contains [u].
String _regionIdForUnitInWorld(WorldState ws, Unit u) {
  if (ProvinceId.isPrefixed(u.locationProvinceId)) {
    return ProvinceId.regionIdFrom(u.locationProvinceId);
  }
  if (ws.oldWorld.units.any((x) => x.id == u.id)) {
    return kRegionOldWorld;
  }
  if (ws.newWorld.units.any((x) => x.id == u.id)) {
    return kRegionNewWorld;
  }
  throw StateError('Military unit ${u.id} not found in world state regions');
}

/// Ensures every military regiment is in exactly one army and every GP has a home army.
/// Rebuilds from units when [WorldState.armies] is empty or membership is invalid.
Game ensureMilitaryArmiesForGame(Game game) {
  if (_armiesMatchUnits(game)) {
    return _ensureHomeArmiesExist(game);
  }
  return _rebuildArmiesFromMilitaryUnits(game);
}

bool _armiesMatchUnits(Game game) {
  final ws = game.worldState;
  final militaryUnits = [
    ...ws.oldWorld.units.where((u) => isMilitaryUnit(u.type)),
    ...ws.newWorld.units.where((u) => isMilitaryUnit(u.type)),
  ];
  if (ws.armies.isEmpty) {
    return militaryUnits.isEmpty;
  }
  final claimed = <String, String>{}; // unitId -> armyId
  for (final a in ws.armies) {
    for (final uid in a.regimentUnitIds) {
      if (claimed.containsKey(uid)) return false;
      claimed[uid] = a.id;
    }
  }
  for (final u in militaryUnits) {
    if (claimed[u.id] == null) return false;
  }
  for (final uid in claimed.keys) {
    if (!militaryUnits.any((u) => u.id == uid)) return false;
  }
  for (final a in ws.armies) {
    for (final uid in a.regimentUnitIds) {
      final u = _findUnit(game, uid);
      if (u == null) return false;
      if (u.ownerId != a.ownerId) return false;
      if (u.locationProvinceId != a.stationedProvinceId) return false;
    }
  }
  return true;
}

Unit? _findUnit(Game game, String unitId) {
  for (final u in game.worldState.oldWorld.units) {
    if (u.id == unitId) return u;
  }
  for (final u in game.worldState.newWorld.units) {
    if (u.id == unitId) return u;
  }
  return null;
}

Game _ensureHomeArmiesExist(Game game) {
  var ws = game.worldState;
  final armies = List<Army>.from(ws.armies);
  var changed = false;
  for (final player in game.players) {
    final cap = player.capitalProvinceId;
    if (cap == null) continue;
    final hid = homeArmyIdFor(player.id);
    final exists = armies.any((a) => a.id == hid && a.ownerId == player.id);
    if (!exists) {
      final regionId = _regionIdForProvinceInWorld(ws, cap);
      armies.add(
        Army(
          id: hid,
          ownerId: player.id,
          regionId: regionId,
          stationedProvinceId: cap,
          regimentUnitIds: const [],
          isHomeArmy: true,
        ),
      );
      changed = true;
    }
  }
  if (!changed) return game;
  return game.copyWith(worldState: ws.copyWith(armies: armies));
}

Game _rebuildArmiesFromMilitaryUnits(Game game) {
  final ws = game.worldState;
  final militaryUnits = [
    ...ws.oldWorld.units.where((u) => isMilitaryUnit(u.type)),
    ...ws.newWorld.units.where((u) => isMilitaryUnit(u.type)),
  ];

  final capitals = {
    for (final p in game.players)
      if (p.capitalProvinceId != null) p.id: p.capitalProvinceId!,
  };

  final byArmyKey = <String, List<String>>{};

  for (final u in militaryUnits) {
    final cap = capitals[u.ownerId];
    final isGpHome = cap != null && u.locationProvinceId == cap;
    final key = isGpHome
        ? homeArmyIdFor(u.ownerId)
        : fieldArmyIdFor(u.ownerId, u.locationProvinceId);
    byArmyKey.putIfAbsent(key, () => []).add(u.id);
  }

  final armies = <Army>[];

  for (final player in game.players) {
    final cap = player.capitalProvinceId;
    if (cap == null) continue;
    final hid = homeArmyIdFor(player.id);
    final regionId = _regionIdForProvinceInWorld(ws, cap);
    armies.add(
      Army(
        id: hid,
        ownerId: player.id,
        regionId: regionId,
        stationedProvinceId: cap,
        regimentUnitIds: List<String>.from(byArmyKey[hid] ?? const []),
        isHomeArmy: true,
      ),
    );
    byArmyKey.remove(hid);
  }

  for (final e in byArmyKey.entries) {
    if (e.value.isEmpty) continue;
    final sample = militaryUnits.firstWhere((u) => u.id == e.value.first);
    final regionId = _regionIdForUnitInWorld(ws, sample);
    armies.add(
      Army(
        id: e.key,
        ownerId: sample.ownerId,
        regionId: regionId,
        stationedProvinceId: sample.locationProvinceId,
        regimentUnitIds: List<String>.from(e.value)..sort(),
        isHomeArmy: false,
      ),
    );
  }

  armies.sort((a, b) => a.id.compareTo(b.id));

  var nextSeq = 1;
  for (final a in armies) {
    if (!a.isHomeArmy && a.id.startsWith('army_field_')) {
      nextSeq++;
    }
  }

  return game.copyWith(
    worldState: ws.copyWith(
      armies: armies,
      nextArmySeq: nextSeq < 2 ? 2 : nextSeq,
    ),
  );
}

/// Removes dead unit ids from armies, drops empty non-home armies, assigns orphan regiments.
WorldState reconcileArmiesAfterUnitsChanged(WorldState worldState, Game game) {
  final unitIds = <String>{
    ...worldState.oldWorld.units.map((u) => u.id),
    ...worldState.newWorld.units.map((u) => u.id),
  };
  var armies = worldState.armies
      .map(
        (a) => a.copyWith(
          regimentUnitIds: a.regimentUnitIds
              .where(unitIds.contains)
              .toList(growable: false),
        ),
      )
      .where((a) => a.isHomeArmy || a.regimentUnitIds.isNotEmpty)
      .toList();

  final claimed = <String>{for (final a in armies) ...a.regimentUnitIds};

  final military = [
    ...worldState.oldWorld.units.where((u) => isMilitaryUnit(u.type)),
    ...worldState.newWorld.units.where((u) => isMilitaryUnit(u.type)),
  ];

  final capitals = {
    for (final p in game.players)
      if (p.capitalProvinceId != null) p.id: p.capitalProvinceId!,
  };

  Army? findArmy(String id) {
    for (final a in armies) {
      if (a.id == id) return a;
    }
    return null;
  }

  for (final u in military) {
    if (claimed.contains(u.id)) continue;
    final cap = capitals[u.ownerId];
    final wantsHome = cap != null && u.locationProvinceId == cap;
    final targetId = wantsHome
        ? homeArmyIdFor(u.ownerId)
        : fieldArmyIdFor(u.ownerId, u.locationProvinceId);
    var target = findArmy(targetId);
    if (target == null) {
      final regionId = _regionIdForUnitInWorld(worldState, u);
      target = Army(
        id: targetId,
        ownerId: u.ownerId,
        regionId: regionId,
        stationedProvinceId: u.locationProvinceId,
        regimentUnitIds: const [],
        isHomeArmy: wantsHome,
      );
      armies = [...armies, target];
    }
    final updated = target.copyWith(
      regimentUnitIds: [...target.regimentUnitIds, u.id],
    );
    armies = armies.map((a) => a.id == target!.id ? updated : a).toList();
    claimed.add(u.id);
  }

  armies.sort((a, b) => a.id.compareTo(b.id));
  return worldState.copyWith(armies: armies);
}

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

  var owUnits = List<Unit>.from(worldState.oldWorld.units);
  var nwUnits = List<Unit>.from(worldState.newWorld.units);

  for (final rid in army.regimentUnitIds) {
    final updated = _moveRegimentToProvince(
      owUnits: owUnits,
      nwUnits: nwUnits,
      regimentUnitId: rid,
      destinationProvinceId: destinationProvinceId,
      destinationRegionId: regionId,
    );
    owUnits = updated.owUnits;
    nwUnits = updated.nwUnits;
  }

  return worldState.copyWith(
    armies: armies,
    oldWorld: RegionData(
      provinces: worldState.oldWorld.provinces,
      units: owUnits,
    ),
    newWorld: RegionData(
      provinces: worldState.newWorld.provinces,
      units: nwUnits,
    ),
  );
}

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

Army? _armyById(List<Army> armies, String armyId) {
  final armyList = armies.where((a) => a.id == armyId).toList();
  return armyList.isEmpty ? null : armyList.first;
}

({List<Unit> owUnits, List<Unit> nwUnits}) _moveRegimentToProvince({
  required List<Unit> owUnits,
  required List<Unit> nwUnits,
  required String regimentUnitId,
  required String destinationProvinceId,
  required String destinationRegionId,
}) {
  final owIdx = owUnits.indexWhere((u) => u.id == regimentUnitId);
  final nwIdx = nwUnits.indexWhere((u) => u.id == regimentUnitId);
  if (owIdx < 0 && nwIdx < 0) return (owUnits: owUnits, nwUnits: nwUnits);

  final inOldWorld = owIdx >= 0;
  final sourceRegion = inOldWorld ? kRegionOldWorld : kRegionNewWorld;
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
    owIdx: owIdx,
    nwIdx: nwIdx,
    destinationProvinceId: destinationProvinceId,
    destinationRegionId: destinationRegionId,
    inOldWorld: inOldWorld,
  );
}

({List<Unit> owUnits, List<Unit> nwUnits}) _relocateRegimentInSameRegion({
  required List<Unit> owUnits,
  required List<Unit> nwUnits,
  required String regimentUnitId,
  required String destinationProvinceId,
  required bool inOldWorld,
}) {
  if (inOldWorld) {
    return (
      owUnits: owUnits
          .map(
            (u) => u.id == regimentUnitId
                ? u.copyWith(locationProvinceId: destinationProvinceId)
                : u,
          )
          .toList(),
      nwUnits: nwUnits,
    );
  }
  return (
    owUnits: owUnits,
    nwUnits: nwUnits
        .map(
          (u) => u.id == regimentUnitId
              ? u.copyWith(locationProvinceId: destinationProvinceId)
              : u,
        )
        .toList(),
  );
}

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
