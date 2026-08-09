import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_save/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:hive/hive.dart';

import 'game_save_envelope_codec.dart';
import 'game_save_list_gate.dart';
import 'game_save_map_data_store.dart';
import 'game_save_session.dart';
import 'loadable_save_entry.dart';

export 'game_save_envelope_codec.dart' show kSaveFormatVersion;
export 'game_save_list_gate.dart'
    show kAutoSaveListLabel, kListGateSaveFormatVersion;

final _log = packageLogger();

/// Max manual named saves for **new** create; overwrite still allowed at cap.
/// SPEC/program/save-load-list-metadata.md.
const int kMaxManualSaves = 20;

/// Fixed Hive key stem for the single auto-save slot. Not listed in [listGameIds].
/// See SPEC/program/save-load.md § Auto-save slot.
const String kAutoSaveSlotId = '__colonizethis_autosave';

/// Saves and loads [Game] state to/from a Hive box. One entry per game, keyed by [Game.id].
/// Map data (tile maps, topology) is required for playable saves. See SPEC/program/save-load.md.
class GameSaveAdapter {
  /// Saves [game] to [box] as a versioned envelope (optionally with mid-turn drafts).
  /// [lastSavedAt] defaults to UTC now; inject in tests for deterministic ordering.
  void save(
    Box<dynamic> box,
    Game game, {
    Orders draftOrders = const Orders(),
    Map<String, int> productionDesiredOutputByRecipe = const <String, int>{},
    String? displayName,
    DateTime? lastSavedAt,
  }) {
    _log.i('saving gameId=${game.id}');
    box.put(
      game.id,
      buildGameSaveEnvelope(
        game,
        draftOrders: draftOrders,
        productionDesiredOutputByRecipe: productionDesiredOutputByRecipe,
        displayName: displayName,
        lastSavedAt: lastSavedAt,
      ),
    );
    _log.i('saved gameId=${game.id}');
  }

  /// Writes [game] and map data under [kAutoSaveSlotId] (mirrors a playable session).
  /// [Game.id] inside JSON remains the real session id. SPEC/program/save-load.md.
  void saveAutoSave(
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
    box.put(
      kAutoSaveSlotId,
      buildGameSaveEnvelope(
        game,
        draftOrders: draftOrders,
        productionDesiredOutputByRecipe: productionDesiredOutputByRecipe,
        displayName: displayName,
        lastSavedAt: lastSavedAt,
      ),
    );
    saveMapData(
      box,
      kAutoSaveSlotId,
      tileMapByRegion: tileMapByRegion,
      topologyByRegion: topologyByRegion,
      combinedTopology: combinedTopology,
      warpLinks: warpLinks,
    );
    _log.i('saved auto-save slot logicalGameId=${game.id}');
  }

  /// Returns true when the auto-save slot holds a playable game + map data.
  /// On invalid or partial data, clears the slot and logs with prefix `save:`.
  bool hasValidAutoSave(Box<dynamic> box) {
    if (!box.containsKey(kAutoSaveSlotId)) {
      _removeOrphanAutosaveMapKeys(box);
      return false;
    }
    final game = load(box, kAutoSaveSlotId);
    if (game == null) {
      _log.w('save: auto-save game JSON invalid; clearing slot');
      delete(box, kAutoSaveSlotId);
      return false;
    }
    try {
      loadMapData(box, kAutoSaveSlotId);
      return true;
    } catch (e, st) {
      _log.w(
        'save: auto-save map data invalid; clearing slot',
        error: e,
        stackTrace: st,
      );
      delete(box, kAutoSaveSlotId);
      return false;
    }
  }

  void _removeOrphanAutosaveMapKeys(Box<dynamic> box) {
    if (box.containsKey(kAutoSaveSlotId)) {
      return;
    }
    if (hasAnyGameMapDataKey(box, kAutoSaveSlotId)) {
      _log.w('save: clearing orphan auto-save map keys');
      delete(box, kAutoSaveSlotId);
    }
  }

  /// Loads game by [gameId]. Returns null if not found or invalid.
  Game? load(Box<dynamic> box, String gameId) => loadSession(box, gameId)?.game;

  /// Loads [gameId] with mid-turn draft fields. Missing draft keys default to
  /// empty [Orders] / `{}` / null [GameSaveSession.displayName].
  GameSaveSession? loadSession(Box<dynamic> box, String gameId) {
    _log.i('loading gameId=$gameId');
    final raw = box.get(gameId);
    if (raw == null) {
      _log.w('gameId=$gameId not found');
      return null;
    }
    try {
      final envelope = Map<String, dynamic>.from(raw as Map<dynamic, dynamic>);
      final session = parseGameSaveSessionEnvelope(envelope, gameId: gameId);
      _log.i('loaded gameId=$gameId');
      return session;
    } catch (e, st) {
      _log.e('load failed gameId=$gameId', error: e, stackTrace: st);
      return null;
    }
  }

  /// Loads [gameId] or throws [IncompatibleSaveFormatException] when the stored
  /// [saveFormatVersion] is missing or unsupported, or the payload is not a map.
  /// Returns null only when [gameId] is absent from [box].
  Game? loadStrict(Box<dynamic> box, String gameId) =>
      loadSessionStrict(box, gameId)?.game;

  /// Strict variant of [loadSession].
  GameSaveSession? loadSessionStrict(Box<dynamic> box, String gameId) {
    _log.i('loading strict gameId=$gameId');
    final raw = box.get(gameId);
    if (raw == null) {
      _log.w('gameId=$gameId not found');
      return null;
    }
    final envelope = Map<String, dynamic>.from(raw as Map<dynamic, dynamic>);
    final session = parseGameSaveSessionEnvelope(envelope, gameId: gameId);
    _log.i('loaded strict gameId=$gameId');
    return session;
  }

  /// Lists all game ids stored in [box]. Excludes internal map-data keys.
  List<String> listGameIds(Box<dynamic> box) =>
      listStoredGameIds(box, autoSaveSlotId: kAutoSaveSlotId);

  /// Count of manual Hive game ids (auto-save stem excluded).
  int manualSaveCount(Box<dynamic> box) => listGameIds(box).length;

  /// Whether a **new** sanitized manual id may be created (count < [kMaxManualSaves]).
  bool canCreateNewManualSave(Box<dynamic> box) =>
      manualSaveCount(box) < kMaxManualSaves;

  /// List-gate manuals (newest first) plus pinned auto-save when listable.
  /// Reads envelope `listMeta` without [Game.fromJson]. Refs #3985.
  List<LoadableSaveEntry> listLoadableSaves(Box<dynamic> box) {
    final manuals = <LoadableSaveEntry>[];
    for (final id in listGameIds(box)) {
      final entry = tryParseLoadableSaveEntry(
        storageId: id,
        raw: box.get(id),
        kind: LoadableSaveKind.manual,
      );
      if (entry != null) {
        manuals.add(entry);
      }
    }

    LoadableSaveEntry? auto;
    if (hasValidAutoSave(box)) {
      auto = tryParseLoadableSaveEntry(
        storageId: kAutoSaveSlotId,
        raw: box.get(kAutoSaveSlotId),
        kind: LoadableSaveKind.autoSave,
        forcedLabel: kAutoSaveListLabel,
      );
    }
    return assembleLoadableSaveList(manuals: manuals, autoEntry: auto);
  }

  /// Saves required map data for [gameId].
  void saveMapData(
    Box<dynamic> box,
    String gameId, {
    required Map<String, TileMapResult> tileMapByRegion,
    required Map<String, MapTopology> topologyByRegion,
    required MapTopology combinedTopology,
    List<WarpLink>? warpLinks,
  }) {
    saveGameMapData(
      box,
      gameId,
      tileMapByRegion: tileMapByRegion,
      topologyByRegion: topologyByRegion,
      combinedTopology: combinedTopology,
      warpLinks: warpLinks,
    );
  }

  /// Loads required map data for [gameId].
  ///
  /// Throws [StateError] when any required key is missing.
  /// Throws [FormatException] when map data exists but is invalid.
  ({
    Map<String, TileMapResult> tileMapByRegion,
    Map<String, MapTopology> topologyByRegion,
    MapTopology combinedTopology,
    List<WarpLink>? warpLinks,
  })
  loadMapData(Box<dynamic> box, String gameId) => loadGameMapData(box, gameId);

  /// Deletes game [gameId] from [box]. No-op if not present. Also removes map data keys.
  void delete(Box<dynamic> box, String gameId) {
    box.delete(gameId);
    deleteGameMapDataKeys(box, gameId);
  }
}
