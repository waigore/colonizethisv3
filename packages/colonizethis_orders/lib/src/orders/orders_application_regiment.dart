import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';

/// Returns [game] with [newUnitId] appended to the appropriate army for [player].
///
/// When [armiesById] is supplied it MUST be a snapshot of `game.worldState.armies`
/// keyed by army id (see [armiesByIdForWorld]). It enables O(1) existence
/// lookup and bypasses the per-call `indexWhere` over `worldState.armies`,
/// which would otherwise be O(armyCount) per recruited unit and degrade build
/// phases that spawn many regiments for the same player. Refs #2394,
/// SPEC/program/order-suggestions.md § Throughput bounds.
///
/// The function mutates [armiesById] in place so subsequent calls observe the
/// just-updated/added entry: callers can build the map once at the start of a
/// build phase and pass the same reference across every recruit. Pass `null`
/// (or omit) to fall back to a single-pass scan that preserves the legacy
/// behavior for one-off uses.
Game appendMilitaryRegimentToArmy(
  Game game,
  Player player,
  String spawnProvinceId,
  String newUnitId, {
  Map<String, Army>? armiesById,
}) {
  final cap = player.capitalProvinceId;
  final atHome =
      cap != null &&
      (spawnProvinceId == cap ||
          (ProvinceId.regionIdFrom(spawnProvinceId) ==
                  ProvinceId.regionIdFrom(cap) &&
              ProvinceId.localIdFrom(spawnProvinceId) ==
                  ProvinceId.localIdFrom(cap)));
  final armyId = atHome
      ? homeArmyIdFor(player.id)
      : fieldArmyIdFor(player.id, spawnProvinceId);
  final ws = game.worldState;
  final regionId = ProvinceId.regionIdFrom(spawnProvinceId);

  // O(1) hot-path: when the caller supplied a snapshot map, look up by id and
  // require ownership match; missing entries fall back to the linear scan in
  // case the supplied map was built before a recent army insertion. Refs #2394.
  final Army? existing;
  if (armiesById != null) {
    final candidate = armiesById[armyId];
    existing = (candidate != null && candidate.ownerId == player.id)
        ? candidate
        : _firstArmyByIdAndOwner(ws.armies, armyId, player.id);
  } else {
    existing = _firstArmyByIdAndOwner(ws.armies, armyId, player.id);
  }
  if (existing != null) {
    final updated = existing.copyWith(
      regimentUnitIds: [...existing.regimentUnitIds, newUnitId],
    );
    final next = <Army>[
      for (final a in ws.armies)
        if (a.id == armyId && a.ownerId == player.id) updated else a,
    ];
    armiesById?[armyId] = updated;
    return game.withArmies(next);
  }
  final stationed = atHome ? cap : spawnProvinceId;
  final newArmy = Army(
    id: armyId,
    ownerId: player.id,
    regionId: regionId,
    stationedProvinceId: stationed,
    regimentUnitIds: [newUnitId],
    isHomeArmy: atHome,
  );
  final next = [...ws.armies, newArmy]..sort((a, b) => a.id.compareTo(b.id));
  armiesById?[newArmy.id] = newArmy;
  return game.withArmies(next);
}

Army? _firstArmyByIdAndOwner(List<Army> armies, String armyId, String ownerId) {
  for (final a in armies) {
    if (a.id == armyId && a.ownerId == ownerId) return a;
  }
  return null;
}
