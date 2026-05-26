import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import 'army_ids.dart';
import 'game_world_mutations.dart';
import 'province_lookup.dart';
import 'unit_lookup.dart';

/// Prefixed ids use [ProvinceId.regionIdFrom]; otherwise resolve from [WorldState]
/// (legacy tests and fixtures may use local province ids only).
String _regionIdForProvinceInWorld(WorldState ws, String provinceId) {
  if (ProvinceId.isPrefixed(provinceId)) {
    return ProvinceId.regionIdFrom(provinceId);
  }
  final region = ws.tryGetRegionIdForLegacyProvinceKey(provinceId);
  if (region == null) {
    throw StateError('Province id not found in either region: "$provinceId"');
  }
  return region;
}

/// Prefixed [Unit.locationProvinceId] uses [ProvinceId.regionIdFrom]; otherwise
/// infer region from which regional unit list contains [u].
String _regionIdForUnitInWorld(WorldState ws, Unit u) {
  if (ProvinceId.isPrefixed(u.locationProvinceId)) {
    return ProvinceId.regionIdFrom(u.locationProvinceId);
  }
  final region = ws.tryGetRegionIdForUnit(u);
  if (region == null) {
    throw StateError('Military unit ${u.id} not found in world state regions');
  }
  return region;
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
  final militaryUnits = allUnitsFromWorld(
    ws,
  ).where((u) => isMilitaryUnit(u.type)).toList();
  final militaryUnitIds = {for (final unit in militaryUnits) unit.id};
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
    if (!militaryUnitIds.contains(uid)) return false;
  }
  for (final a in ws.armies) {
    for (final uid in a.regimentUnitIds) {
      final u = game.worldState.tryGetUnitById(uid);
      if (u == null) return false;
      if (u.ownerId != a.ownerId) return false;
      if (u.locationProvinceId != a.stationedProvinceId) return false;
    }
  }
  return true;
}

Game _ensureHomeArmiesExist(Game game) {
  final ws = game.worldState;
  final armies = List<Army>.from(ws.armies);
  var changed = false;
  for (final player in game.players) {
    changed = _ensureHomeArmyForPlayer(ws, armies, player) || changed;
  }
  if (!changed) return game;
  return game.withArmies(armies);
}

bool _ensureHomeArmyForPlayer(WorldState ws, List<Army> armies, Player player) {
  final cap = player.capitalProvinceId;
  if (cap == null) return false;
  final hid = homeArmyIdFor(player.id);
  for (final a in armies) {
    if (a.id == hid && a.ownerId == player.id) {
      return false;
    }
  }
  armies.add(_homeArmyForPlayerAtCapital(ws, player, cap));
  return true;
}

Army _homeArmyForPlayerAtCapital(WorldState ws, Player player, String cap) =>
    Army(
      id: homeArmyIdFor(player.id),
      ownerId: player.id,
      regionId: _regionIdForProvinceInWorld(ws, cap),
      stationedProvinceId: cap,
      regimentUnitIds: const [],
      isHomeArmy: true,
    );

Game _rebuildArmiesFromMilitaryUnits(Game game) {
  final ws = game.worldState;
  final militaryUnits = _militaryUnitsFromWorld(ws);
  final capitals = _capitalByPlayer(game.players);
  final byArmyKey = _armyMembershipByKey(militaryUnits, capitals);
  final armies = <Army>[];
  _appendHomeArmies(ws, game.players, byArmyKey, armies);
  _appendFieldArmies(ws, byArmyKey, militaryUnits, armies);
  armies.sort((a, b) => a.id.compareTo(b.id));
  final nextSeq = _nextArmySequence(armies);
  return game.updateWorldState(
    (ws) => ws.copyWith(armies: armies, nextArmySeq: nextSeq < 2 ? 2 : nextSeq),
  );
}

List<Unit> _militaryUnitsFromWorld(WorldState ws) {
  final out = <Unit>[];
  for (final u in allUnitsFromWorld(ws)) {
    if (isMilitaryUnit(u.type)) {
      out.add(u);
    }
  }
  return out;
}

Map<String, String> _capitalByPlayer(List<Player> players) => {
  for (final p in players)
    if (p.capitalProvinceId != null) p.id: p.capitalProvinceId!,
};

Map<String, List<String>> _armyMembershipByKey(
  List<Unit> militaryUnits,
  Map<String, String> capitals,
) {
  final byArmyKey = <String, List<String>>{};
  for (final u in militaryUnits) {
    final key = _armyKeyForUnit(u, capitals);
    byArmyKey.putIfAbsent(key, () => []).add(u.id);
  }
  return byArmyKey;
}

String _armyKeyForUnit(Unit u, Map<String, String> capitals) {
  final cap = capitals[u.ownerId];
  final isGpHome = cap != null && u.locationProvinceId == cap;
  return isGpHome
      ? homeArmyIdFor(u.ownerId)
      : fieldArmyIdFor(u.ownerId, u.locationProvinceId);
}

void _appendHomeArmies(
  WorldState ws,
  List<Player> players,
  Map<String, List<String>> byArmyKey,
  List<Army> armies,
) {
  for (final player in players) {
    final home = _homeArmyFromPlayerAndMembership(ws, player, byArmyKey);
    if (home == null) continue;
    armies.add(home.army);
    byArmyKey.remove(home.id);
  }
}

({String id, Army army})? _homeArmyFromPlayerAndMembership(
  WorldState ws,
  Player player,
  Map<String, List<String>> byArmyKey,
) {
  final cap = player.capitalProvinceId;
  if (cap == null) return null;
  final hid = homeArmyIdFor(player.id);
  return (
    id: hid,
    army: Army(
      id: hid,
      ownerId: player.id,
      regionId: _regionIdForProvinceInWorld(ws, cap),
      stationedProvinceId: cap,
      regimentUnitIds: List<String>.from(byArmyKey[hid] ?? const []),
      isHomeArmy: true,
    ),
  );
}

void _appendFieldArmies(
  WorldState ws,
  Map<String, List<String>> byArmyKey,
  List<Unit> militaryUnits,
  List<Army> armies,
) {
  for (final e in byArmyKey.entries) {
    final field = _fieldArmyFromEntry(ws, e, militaryUnits);
    if (field == null) continue;
    armies.add(field);
  }
}

Army? _fieldArmyFromEntry(
  WorldState ws,
  MapEntry<String, List<String>> e,
  List<Unit> militaryUnits,
) {
  if (e.value.isEmpty) return null;
  final sample = militaryUnits.firstWhere((u) => u.id == e.value.first);
  return Army(
    id: e.key,
    ownerId: sample.ownerId,
    regionId: _regionIdForUnitInWorld(ws, sample),
    stationedProvinceId: sample.locationProvinceId,
    regimentUnitIds: List<String>.from(e.value)..sort(),
    isHomeArmy: false,
  );
}

int _nextArmySequence(List<Army> armies) {
  var nextSeq = 1;
  for (final a in armies) {
    if (!a.isHomeArmy && a.id.startsWith('army_field_')) nextSeq++;
  }
  return nextSeq < 2 ? 2 : nextSeq;
}

/// Removes dead unit ids from armies, drops empty non-home armies, assigns orphan regiments.
WorldState reconcileArmiesAfterUnitsChanged(WorldState worldState, Game game) {
  final unitIds = <String>{for (final u in allUnitsFromWorld(worldState)) u.id};
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

  final military = allUnitsFromWorld(
    worldState,
  ).where((u) => isMilitaryUnit(u.type)).toList();

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
  final relocated = _relocateArmyRegiments(
    regimentUnitIds: army.regimentUnitIds,
    owUnits: List<Unit>.from(worldState.oldWorld.units),
    nwUnits: List<Unit>.from(worldState.newWorld.units),
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
