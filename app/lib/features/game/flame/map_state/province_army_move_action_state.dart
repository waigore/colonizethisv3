import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../caches/per_player_army_move_picker_cache.dart';

/// Visibility/enablement for MAP20001 Military Move / Invade (Refs #4350).
///
/// Visibility uses cheap topology/ownership predicates; enablement reads
/// [PerPlayerArmyMovePickerCache] only — never live `armyMovePickerDestinations`.
class ProvinceArmyMoveActionState {
  const ProvinceArmyMoveActionState({
    required this.showMove,
    required this.moveEnabled,
    required this.moveDisabledReason,
    required this.eligibleMoveArmyIds,
    required this.showInvade,
    required this.invadeEnabled,
    required this.invadeDisabledReason,
    required this.eligibleInvadeArmyIds,
  });

  static const hidden = ProvinceArmyMoveActionState(
    showMove: false,
    moveEnabled: false,
    moveDisabledReason: ProvinceArmyMoveDisabledReason.none,
    eligibleMoveArmyIds: <String>[],
    showInvade: false,
    invadeEnabled: false,
    invadeDisabledReason: ProvinceArmyMoveDisabledReason.none,
    eligibleInvadeArmyIds: <String>[],
  );

  final bool showMove;
  final bool moveEnabled;
  final ProvinceArmyMoveDisabledReason moveDisabledReason;
  final List<String> eligibleMoveArmyIds;
  final bool showInvade;
  final bool invadeEnabled;
  final ProvinceArmyMoveDisabledReason invadeDisabledReason;
  final List<String> eligibleInvadeArmyIds;
}

enum ProvinceArmyMoveDisabledReason {
  none,
  homeArmyCannotLeave,
  noDestinations,
  cannotReach,
}

/// Computes Move/Invade action state for [provinceId] (prefixed full id).
ProvinceArmyMoveActionState computeProvinceArmyMoveActionState({
  required Game game,
  required String humanPlayerId,
  required String provinceId,
  required MapTopology topology,
  required PerPlayerArmyMovePickerCache armyMovePickerCache,
  required bool showsFullMilitaryIntel,
  required bool isSeaZoneContext,
}) {
  if (isSeaZoneContext || !showsFullMilitaryIntel) {
    return ProvinceArmyMoveActionState.hidden;
  }

  final province = game.worldState.tryGetProvince(provinceId);
  if (province == null) return ProvinceArmyMoveActionState.hidden;

  final ownerId = province.ownerId;
  final isOwned = ownerId == humanPlayerId;

  if (isOwned) {
    return _moveStateForOwnedProvince(
      game: game,
      humanPlayerId: humanPlayerId,
      provinceId: provinceId,
      armyMovePickerCache: armyMovePickerCache,
    );
  }

  if (ownerId == null || !_hasInvasionOwnerSemantics(game, ownerId)) {
    return ProvinceArmyMoveActionState.hidden;
  }

  final conceivable = invadeConceivableCheap(
    game: game,
    topology: topology,
    humanPlayerId: humanPlayerId,
    targetFullProvinceId: provinceId,
  );
  if (!conceivable) {
    return ProvinceArmyMoveActionState.hidden;
  }

  final reachable = armyMovePickerCache.armyIdsThatCanReach(
    humanPlayerId,
    provinceId,
  );
  return ProvinceArmyMoveActionState(
    showMove: false,
    moveEnabled: false,
    moveDisabledReason: ProvinceArmyMoveDisabledReason.none,
    eligibleMoveArmyIds: const [],
    showInvade: true,
    invadeEnabled: reachable.isNotEmpty,
    invadeDisabledReason: reachable.isEmpty
        ? ProvinceArmyMoveDisabledReason.cannotReach
        : ProvinceArmyMoveDisabledReason.none,
    eligibleInvadeArmyIds: reachable,
  );
}

ProvinceArmyMoveActionState _moveStateForOwnedProvince({
  required Game game,
  required String humanPlayerId,
  required String provinceId,
  required PerPlayerArmyMovePickerCache armyMovePickerCache,
}) {
  final fieldIds = armyMovePickerCache.stationedFieldArmyIdsInProvince(
    humanPlayerId,
    provinceId,
    game,
  );
  final hasHomeOnly = fieldIds.isEmpty &&
      game.worldState.armies.any(
        (a) =>
            a.ownerId == humanPlayerId &&
            a.isHomeArmy &&
            a.stationedProvinceId == provinceId,
      );

  if (fieldIds.isEmpty && !hasHomeOnly) {
    return ProvinceArmyMoveActionState.hidden;
  }

  if (hasHomeOnly) {
    return const ProvinceArmyMoveActionState(
      showMove: true,
      moveEnabled: false,
      moveDisabledReason: ProvinceArmyMoveDisabledReason.homeArmyCannotLeave,
      eligibleMoveArmyIds: [],
      showInvade: false,
      invadeEnabled: false,
      invadeDisabledReason: ProvinceArmyMoveDisabledReason.none,
      eligibleInvadeArmyIds: [],
    );
  }

  final withDest = armyMovePickerCache.stationedFieldArmyIdsWithDestinations(
    humanPlayerId,
    provinceId,
    game,
  );
  return ProvinceArmyMoveActionState(
    showMove: true,
    moveEnabled: withDest.isNotEmpty,
    moveDisabledReason: withDest.isEmpty
        ? ProvinceArmyMoveDisabledReason.noDestinations
        : ProvinceArmyMoveDisabledReason.none,
    eligibleMoveArmyIds: withDest.isNotEmpty ? withDest : fieldIds,
    showInvade: false,
    invadeEnabled: false,
    invadeDisabledReason: ProvinceArmyMoveDisabledReason.none,
    eligibleInvadeArmyIds: const [],
  );
}

/// Cheap Invade visibility predicate (topology + army stationing only).
bool invadeConceivableCheap({
  required Game game,
  required MapTopology topology,
  required String humanPlayerId,
  required String targetFullProvinceId,
}) {
  final regionId = ProvinceId.regionIdFrom(targetFullProvinceId);
  final localId = ProvinceId.localIdFrom(targetFullProvinceId);
  final fieldInRegion = <Army>[
    for (final army in game.worldState.armies)
      if (army.ownerId == humanPlayerId &&
          !army.isHomeArmy &&
          army.regimentUnitIds.isNotEmpty &&
          ProvinceId.regionIdFrom(army.stationedProvinceId) == regionId)
        army,
  ];
  if (fieldInRegion.isEmpty) return false;

  final neighborLocals =
      neighborProvinceIdsInRegion(topology, regionId, localId).toSet();
  for (final army in fieldInRegion) {
    final hostLocal = ProvinceId.localIdFrom(army.stationedProvinceId);
    if (neighborLocals.contains(hostLocal)) return true;
  }
  return false;
}

bool _hasInvasionOwnerSemantics(Game game, String ownerId) {
  if (ownerId.isEmpty) return false;
  if (game.playerById(ownerId) != null) return true;
  for (final m in game.minorNations) {
    if (m.id == ownerId) return true;
  }
  for (final t in game.tribes) {
    if (t.id == ownerId) return true;
  }
  return false;
}
