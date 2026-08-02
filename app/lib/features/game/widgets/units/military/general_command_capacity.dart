// Human general roster + draft invasion counts for UNIT20001 / DLG20001 (#4233).
// SPEC/game/military-generals.md; SPEC/ui/military-units-panel.md; SPEC/ui/move-army-dialog.md.

import 'package:colonizethis_data/colonizethis_data.dart'
    show generalCapForUnlockedTechs;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show resolveToFullProvinceId;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show GamePlayerLookup, WorldStateProvinceLookup;

/// Effective general cap for a Great Power (persisted cap or tech-derived).
int effectiveGeneralCapForPlayer(Player player) =>
    player.generalCap ?? generalCapForUnlockedTechs(player.techUnlocked);

/// Generals owned by [playerId], stable order by id.
List<General> generalsForPlayer(Game game, String playerId) {
  final list = game.generals.where((g) => g.ownerId == playerId).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  return list;
}

/// Roster count for UI; never shows an empty pool when the cap requires ≥1.
int humanGeneralCountForDisplay(Game game, String playerId) {
  final roster = generalsForPlayer(game, playerId);
  if (roster.isNotEmpty) return roster.length;
  final player = game.playerById(playerId);
  if (player == null) return 0;
  final cap = effectiveGeneralCapForPlayer(player);
  return cap > 0 ? 1 : 0;
}

/// Whether an army move into [destinationProvinceId] is an invasion for [playerId].
bool isArmyMoveInvasionDestination(
  Game game,
  String playerId,
  String destinationProvinceId,
) {
  final full = resolveToFullProvinceId(
    game.worldState,
    destinationProvinceId,
  );
  final province = game.worldState.tryGetProvince(full);
  if (province == null) return true;
  return province.ownerId != playerId;
}

/// Staged invasion army moves this turn, optionally previewing one army's selection.
int stagedInvasionCountForTurn({
  required Game game,
  required String humanPlayerId,
  required Orders draftOrders,
  String? previewArmyId,
  String? previewDestinationProvinceId,
}) {
  final moves =
      draftOrders.armyMoveOrdersByPlayerId[humanPlayerId] ?? const <ArmyMoveOrder>[];
  var count = 0;
  for (final order in moves) {
    if (order.armyId == previewArmyId) continue;
    if (isArmyMoveInvasionDestination(
      game,
      humanPlayerId,
      order.destinationProvinceId,
    )) {
      count++;
    }
  }
  if (previewArmyId != null &&
      previewDestinationProvinceId != null &&
      isArmyMoveInvasionDestination(
        game,
        humanPlayerId,
        previewDestinationProvinceId,
      )) {
    count++;
  }
  return count;
}
