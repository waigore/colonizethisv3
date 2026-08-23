import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../caches/per_player_army_move_picker_cache.dart';
import 'province_army_move_action_state_invade.dart';
import 'province_army_move_home_army.dart';

export 'province_army_move_action_state_invade.dart';

/// Visibility/enablement for MAP20001 Military Move / Invade (Refs #4350).
///
/// Visibility uses cheap topology/ownership predicates. Field enablement
/// reads [PerPlayerArmyMovePickerCache] only; the Home-Army detach clause
/// never reads that cache. Overlay rebuild never calls live
/// `armyMovePickerDestinations`.
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

  if (ownerId == null || !hasInvasionOwnerSemantics(game, ownerId)) {
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
  final homeDetach = homeArmyDetachInvadeCheap(
    game: game,
    topology: topology,
    humanPlayerId: humanPlayerId,
    targetFullProvinceId: provinceId,
  );
  final invadeEnabled = reachable.isNotEmpty || homeDetach;
  return ProvinceArmyMoveActionState(
    showMove: false,
    moveEnabled: false,
    moveDisabledReason: ProvinceArmyMoveDisabledReason.none,
    eligibleMoveArmyIds: const [],
    showInvade: true,
    invadeEnabled: invadeEnabled,
    invadeDisabledReason: invadeEnabled
        ? ProvinceArmyMoveDisabledReason.none
        : ProvinceArmyMoveDisabledReason.cannotReach,
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
  final home = humanHomeArmy(game, humanPlayerId);
  final homeHere = home != null && home.stationedProvinceId == provinceId;
  final homeHereNonEmpty =
      home != null &&
      home.stationedProvinceId == provinceId &&
      home.regimentUnitIds.isNotEmpty;

  if (fieldIds.isEmpty && !homeHere) {
    return ProvinceArmyMoveActionState.hidden;
  }

  final withDest = armyMovePickerCache.stationedFieldArmyIdsWithDestinations(
    humanPlayerId,
    provinceId,
    game,
  );
  if (withDest.isNotEmpty) {
    return ProvinceArmyMoveActionState(
      showMove: true,
      moveEnabled: true,
      moveDisabledReason: ProvinceArmyMoveDisabledReason.none,
      eligibleMoveArmyIds: withDest,
      showInvade: false,
      invadeEnabled: false,
      invadeDisabledReason: ProvinceArmyMoveDisabledReason.none,
      eligibleInvadeArmyIds: const [],
    );
  }
  if (homeHereNonEmpty) {
    return const ProvinceArmyMoveActionState(
      showMove: true,
      moveEnabled: true,
      moveDisabledReason: ProvinceArmyMoveDisabledReason.none,
      eligibleMoveArmyIds: [],
      showInvade: false,
      invadeEnabled: false,
      invadeDisabledReason: ProvinceArmyMoveDisabledReason.none,
      eligibleInvadeArmyIds: [],
    );
  }
  if (fieldIds.isNotEmpty) {
    return ProvinceArmyMoveActionState(
      showMove: true,
      moveEnabled: false,
      moveDisabledReason: ProvinceArmyMoveDisabledReason.noDestinations,
      eligibleMoveArmyIds: fieldIds,
      showInvade: false,
      invadeEnabled: false,
      invadeDisabledReason: ProvinceArmyMoveDisabledReason.none,
      eligibleInvadeArmyIds: const [],
    );
  }
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
