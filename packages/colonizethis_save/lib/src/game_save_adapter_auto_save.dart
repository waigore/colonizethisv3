/// Auto-save slot helpers for [GameSaveAdapter]. Standalone library (no `part`).
/// Refs #4664.
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/package_logger.dart';
import 'package:hive/hive.dart';

import 'game_save_adapter_storage.dart';
import 'game_save_keys.dart' show kAutoSaveSlotId;
import 'game_save_map_data_store.dart';

final _log = packageLogger();

/// Writes [game] and map data under [kAutoSaveSlotId].
void writeAutoSaveSlot(
  Box<dynamic> box,
  Game game, {
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, MapTopology> topologyByRegion,
  required MapTopology combinedTopology,
  List<WarpLink>? warpLinks,
  Orders draftOrders = const Orders(),
  Map<String, int> productionDesiredOutputByRecipe = const <String, int>{},
  String? displayName,
  DateTime? lastSavedAt,
}) {
  _log.i('saving auto-save slot logicalGameId=${game.id}');
  putGameSaveEnvelopeAtStorageId(
    box,
    kAutoSaveSlotId,
    game,
    draftOrders: draftOrders,
    productionDesiredOutputByRecipe: productionDesiredOutputByRecipe,
    displayName: displayName,
    lastSavedAt: lastSavedAt,
  );
  saveGameMapData(
    box,
    kAutoSaveSlotId,
    tileMapByRegion: tileMapByRegion,
    topologyByRegion: topologyByRegion,
    combinedTopology: combinedTopology,
    warpLinks: warpLinks,
  );
  _log.i('saved auto-save slot logicalGameId=${game.id}');
}

/// True when the auto-save slot holds a playable game + map data.
/// On invalid or partial data, clears the slot and logs with prefix `save:`.
bool validateAutoSaveSlot(
  Box<dynamic> box, {
  required Game? Function(Box<dynamic> box, String gameId) loadGame,
  required void Function(Box<dynamic> box, String gameId) deleteSlot,
}) {
  if (!box.containsKey(kAutoSaveSlotId)) {
    clearOrphanAutosaveMapKeys(box, deleteSlot: deleteSlot);
    return false;
  }
  final game = loadGame(box, kAutoSaveSlotId);
  if (game == null) {
    _log.w('save: auto-save game JSON invalid; clearing slot');
    deleteSlot(box, kAutoSaveSlotId);
    return false;
  }
  try {
    loadGameMapData(box, kAutoSaveSlotId);
    return true;
  } catch (e, st) {
    _log.w(
      'save: auto-save map data invalid; clearing slot',
      error: e,
      stackTrace: st,
    );
    deleteSlot(box, kAutoSaveSlotId);
    return false;
  }
}

/// Clears orphan map sidecars when the auto-save stem key is already gone.
void clearOrphanAutosaveMapKeys(
  Box<dynamic> box, {
  required void Function(Box<dynamic> box, String gameId) deleteSlot,
}) {
  if (box.containsKey(kAutoSaveSlotId)) {
    return;
  }
  if (hasAnyGameMapDataKey(box, kAutoSaveSlotId)) {
    _log.w('save: clearing orphan auto-save map keys');
    deleteSlot(box, kAutoSaveSlotId);
  }
}
