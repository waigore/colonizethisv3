import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_save/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:hive/hive.dart';

import 'game_save_session.dart';
import 'incompatible_save_format_exception.dart';
import 'loadable_save_entry.dart';
import 'reconcile_legacy_spy_work.dart';

final _log = packageLogger();

const String _suffixTileMapByRegion = '_tileMapByRegion';
const String _suffixTopologyByRegion = '_topologyByRegion';
const String _suffixCombinedTopology = '_combinedTopology';
const String _suffixWarpLinks = '_warpLinks';
const String _saveFormatVersionKey = 'saveFormatVersion';
const String _saveGamePayloadKey = 'game';
const String _draftOrdersKey = 'draftOrders';
const String _productionDesiredOutputKey = 'productionDesiredOutputByRecipe';
const String _displayNameKey = 'displayName';
const String _listMetaKey = 'listMeta';
const String _listMetaLastSavedAtKey = 'lastSavedAt';
const String _listMetaTurnNumberKey = 'turnNumber';
const String _listMetaCalendarYearKey = 'calendarYear';
const String _listMetaHumanNationKey = 'humanNation';

/// Fixed label for the auto-save row in [listLoadableSaves] (UI may localize).
const String kAutoSaveListLabel = 'Auto-save';

/// Max manual named saves for **new** create; overwrite still allowed at cap.
/// SPEC/program/save-load-list-metadata.md.
const int kMaxManualSaves = 20;

/// Minimum `saveFormatVersion` included by [GameSaveAdapter.listLoadableSaves].
const int kListGateSaveFormatVersion = 3;

const List<String> _mapDataKeySuffixes = <String>[
  _suffixTileMapByRegion,
  _suffixTopologyByRegion,
  _suffixCombinedTopology,
  _suffixWarpLinks,
];

/// Current save format version for game envelopes written by [GameSaveAdapter].
/// v2 adds mid-turn draft fields; v3 adds list metadata (`listMeta`).
/// v1/v2 remain readable; only v3+ appears in [listLoadableSaves].
const int kSaveFormatVersion = 3;
const Set<int> _supportedSaveFormatVersions = {1, 2, kSaveFormatVersion};

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
      _buildEnvelope(
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
      _buildEnvelope(
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

  Map<String, dynamic> _buildEnvelope(
    Game game, {
    required Orders draftOrders,
    required Map<String, int> productionDesiredOutputByRecipe,
    String? displayName,
    DateTime? lastSavedAt,
  }) {
    return <String, dynamic>{
      _saveFormatVersionKey: kSaveFormatVersion,
      _saveGamePayloadKey: game.toJson(),
      _draftOrdersKey: draftOrders.toJson(),
      _productionDesiredOutputKey: productionDesiredOutputByRecipe,
      if (displayName != null) _displayNameKey: displayName,
      _listMetaKey: _buildListMeta(game, lastSavedAt: lastSavedAt),
    };
  }

  Map<String, dynamic> _buildListMeta(Game game, {DateTime? lastSavedAt}) {
    final turn = game.worldState.turnState.turnNumber;
    final mapping = game.turnTimeMapping;
    final year = mapping?.yearAtTurn(turn);
    String? nation;
    for (final player in game.players) {
      if (player.isHuman) {
        nation = player.displayName;
        break;
      }
    }
    final savedAt = (lastSavedAt ?? DateTime.now()).toUtc();
    return <String, dynamic>{
      _listMetaLastSavedAtKey: savedAt.toIso8601String(),
      _listMetaTurnNumberKey: turn,
      if (year != null) _listMetaCalendarYearKey: year,
      if (nation != null && nation.isNotEmpty) _listMetaHumanNationKey: nation,
    };
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
    final hasOrphan =
        box.containsKey(kAutoSaveSlotId + _suffixTileMapByRegion) ||
        box.containsKey(kAutoSaveSlotId + _suffixTopologyByRegion) ||
        box.containsKey(kAutoSaveSlotId + _suffixCombinedTopology) ||
        box.containsKey(kAutoSaveSlotId + _suffixWarpLinks);
    if (hasOrphan) {
      _log.w('save: clearing orphan auto-save map keys');
      delete(box, kAutoSaveSlotId);
    }
  }

  /// Loads game by [gameId]. Returns null if not found or invalid.
  Game? load(Box<dynamic> box, String gameId) =>
      loadSession(box, gameId)?.game;

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
      final versionRaw = envelope[_saveFormatVersionKey];
      if (versionRaw is! int ||
          !_supportedSaveFormatVersions.contains(versionRaw)) {
        throw IncompatibleSaveFormatException(
          'Incompatible save format for gameId=$gameId version=$versionRaw',
        );
      }
      final gameRaw = envelope[_saveGamePayloadKey];
      if (gameRaw is! Map<dynamic, dynamic>) {
        throw IncompatibleSaveFormatException(
          'Invalid save payload for gameId=$gameId',
        );
      }
      final game = reconcileLegacySpyWorkOrders(
        reconcileGeneralsToGeneralCap(
          Game.fromJson(Map<String, dynamic>.from(gameRaw)),
        ),
      );
      final session = GameSaveSession(
        game: game,
        draftOrders: _parseDraftOrders(envelope[_draftOrdersKey]),
        productionDesiredOutputByRecipe: _parseDesiredOutput(
          envelope[_productionDesiredOutputKey],
        ),
        displayName: _parseDisplayName(envelope[_displayNameKey]),
      );
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
    final versionRaw = envelope[_saveFormatVersionKey];
    if (versionRaw is! int ||
        !_supportedSaveFormatVersions.contains(versionRaw)) {
      throw IncompatibleSaveFormatException(
        'Incompatible save format for gameId=$gameId version=$versionRaw',
      );
    }
    final gameRaw = envelope[_saveGamePayloadKey];
    if (gameRaw is! Map<dynamic, dynamic>) {
      throw IncompatibleSaveFormatException(
        'Invalid save payload for gameId=$gameId',
      );
    }
    final game = reconcileLegacySpyWorkOrders(
      reconcileGeneralsToGeneralCap(
        Game.fromJson(Map<String, dynamic>.from(gameRaw)),
      ),
    );
    final session = GameSaveSession(
      game: game,
      draftOrders: _parseDraftOrders(envelope[_draftOrdersKey]),
      productionDesiredOutputByRecipe: _parseDesiredOutput(
        envelope[_productionDesiredOutputKey],
      ),
      displayName: _parseDisplayName(envelope[_displayNameKey]),
    );
    _log.i('loaded strict gameId=$gameId');
    return session;
  }

  Orders _parseDraftOrders(Object? raw) {
    if (raw is! Map<dynamic, dynamic>) {
      return const Orders();
    }
    return Orders.fromJson(Map<String, dynamic>.from(raw));
  }

  Map<String, int> _parseDesiredOutput(Object? raw) {
    if (raw is! Map<dynamic, dynamic>) {
      return const <String, int>{};
    }
    final out = <String, int>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! int || value < 0) {
        continue;
      }
      out[key] = value;
    }
    return out;
  }

  String? _parseDisplayName(Object? raw) {
    if (raw is! String || raw.isEmpty) {
      return null;
    }
    return raw;
  }

  /// Lists all game ids stored in [box]. Excludes internal map-data keys.
  ///
  /// A key is treated as a game id unless it ends with a map-data suffix AND
  /// its prefix exists as a separate key in the box (proving it is map data for
  /// that game). This ensures game ids like `mygame_tileMapByRegion` are not
  /// incorrectly excluded when no corresponding `mygame` key exists.
  List<String> listGameIds(Box<dynamic> box) {
    final allKeys = box.keys.whereType<String>().toSet();

    final definiteGameIds = allKeys
        .where(
          (k) =>
              k != kAutoSaveSlotId &&
              !k.endsWith(_suffixTileMapByRegion) &&
              !k.endsWith(_suffixTopologyByRegion) &&
              !k.endsWith(_suffixCombinedTopology) &&
              !k.endsWith(_suffixWarpLinks),
        )
        .toSet();

    final result = <String>[...definiteGameIds];

    for (final key in allKeys) {
      for (final suffix in _mapDataKeySuffixes) {
        if (!key.endsWith(suffix)) {
          continue;
        }
        final prefix = key.substring(0, key.length - suffix.length);
        if (prefix != kAutoSaveSlotId && !definiteGameIds.contains(prefix)) {
          result.add(key);
        }
        break;
      }
    }

    return result;
  }

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
      final entry = _tryParseListEntry(
        storageId: id,
        raw: box.get(id),
        kind: LoadableSaveKind.manual,
      );
      if (entry != null) {
        manuals.add(entry);
      }
    }
    manuals.sort((a, b) {
      final aAt = a.lastSavedAt;
      final bAt = b.lastSavedAt;
      if (aAt == null && bAt == null) {
        return a.storageId.compareTo(b.storageId);
      }
      if (aAt == null) {
        return 1;
      }
      if (bAt == null) {
        return -1;
      }
      final byTime = bAt.compareTo(aAt);
      if (byTime != 0) {
        return byTime;
      }
      return a.storageId.compareTo(b.storageId);
    });

    final result = <LoadableSaveEntry>[];
    if (hasValidAutoSave(box)) {
      final auto = _tryParseListEntry(
        storageId: kAutoSaveSlotId,
        raw: box.get(kAutoSaveSlotId),
        kind: LoadableSaveKind.autoSave,
        forcedLabel: kAutoSaveListLabel,
      );
      if (auto != null) {
        result.add(auto);
      }
    }
    result.addAll(manuals);
    return result;
  }

  LoadableSaveEntry? _tryParseListEntry({
    required String storageId,
    required Object? raw,
    required LoadableSaveKind kind,
    String? forcedLabel,
  }) {
    if (raw is! Map<dynamic, dynamic>) {
      return null;
    }
    final envelope = Map<String, dynamic>.from(raw);
    final version = envelope[_saveFormatVersionKey];
    if (version is! int || version < kListGateSaveFormatVersion) {
      return null;
    }
    final metaRaw = envelope[_listMetaKey];
    if (metaRaw is! Map<dynamic, dynamic>) {
      return null;
    }
    final meta = Map<String, dynamic>.from(metaRaw);
    final lastSavedRaw = meta[_listMetaLastSavedAtKey];
    if (lastSavedRaw is! String || lastSavedRaw.isEmpty) {
      return null;
    }
    final lastSavedAt = DateTime.tryParse(lastSavedRaw)?.toUtc();
    if (lastSavedAt == null) {
      return null;
    }
    final turnRaw = meta[_listMetaTurnNumberKey];
    final turnNumber = turnRaw is int ? turnRaw : null;
    final yearRaw = meta[_listMetaCalendarYearKey];
    final calendarYear = yearRaw is int ? yearRaw : null;
    final nationRaw = meta[_listMetaHumanNationKey];
    final humanNation = nationRaw is String && nationRaw.isNotEmpty
        ? nationRaw
        : null;
    final displayName = _parseDisplayName(envelope[_displayNameKey]);
    final label =
        forcedLabel ??
        ((displayName != null && displayName.isNotEmpty)
            ? displayName
            : storageId);
    return LoadableSaveEntry(
      storageId: storageId,
      label: label,
      kind: kind,
      turnNumber: turnNumber,
      calendarYear: calendarYear,
      humanNation: humanNation,
      lastSavedAt: lastSavedAt,
    );
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
    _log.d('saving map data gameId=$gameId');
    box.put(
      gameId + _suffixTileMapByRegion,
      tileMapByRegion.map((k, v) => MapEntry(k, v.toJson())),
    );
    box.put(
      gameId + _suffixTopologyByRegion,
      topologyByRegion.map((k, v) => MapEntry(k, v.toJson())),
    );
    box.put(gameId + _suffixCombinedTopology, combinedTopology.toJson());
    if (warpLinks != null) {
      box.put(
        gameId + _suffixWarpLinks,
        warpLinks.map((l) => l.toJson()).toList(),
      );
    }
    _log.d('saved map data gameId=$gameId');
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
  loadMapData(Box<dynamic> box, String gameId) {
    final tileRaw = box.get(gameId + _suffixTileMapByRegion);
    final topoRaw = box.get(gameId + _suffixTopologyByRegion);
    final combinedRaw = box.get(gameId + _suffixCombinedTopology);
    if (tileRaw == null || topoRaw == null || combinedRaw == null) {
      throw StateError('Required map data missing for gameId=$gameId');
    }
    try {
      final tileMapByRegion = (tileRaw as Map<dynamic, dynamic>)
          .map<String, TileMapResult>(
            (k, v) => MapEntry(
              k as String,
              TileMapResult.fromJson(
                Map<String, dynamic>.from(v as Map<dynamic, dynamic>),
              ),
            ),
          );
      final topologyByRegion = (topoRaw as Map<dynamic, dynamic>)
          .map<String, MapTopology>(
            (k, v) => MapEntry(
              k as String,
              MapTopology.fromJson(
                Map<String, dynamic>.from(v as Map<dynamic, dynamic>),
              ),
            ),
          );
      final combinedTopology = MapTopology.fromJson(
        Map<String, dynamic>.from(combinedRaw as Map<dynamic, dynamic>),
      );
      // Warp links are optional for backward compatibility.
      final warpRaw = box.get(gameId + _suffixWarpLinks);
      List<WarpLink>? warpLinks;
      if (warpRaw != null) {
        warpLinks = (warpRaw as List<dynamic>)
            .map(
              (l) => WarpLink.fromJson(
                Map<String, dynamic>.from(l as Map<dynamic, dynamic>),
              ),
            )
            .toList();
      }
      _log.d('loaded map data gameId=$gameId');
      return (
        tileMapByRegion: tileMapByRegion,
        topologyByRegion: topologyByRegion,
        combinedTopology: combinedTopology,
        warpLinks: warpLinks,
      );
    } catch (e, st) {
      _log.e('load map data failed gameId=$gameId', error: e, stackTrace: st);
      throw FormatException('Invalid map data for gameId=$gameId');
    }
  }

  /// Deletes game [gameId] from [box]. No-op if not present. Also removes map data keys.
  void delete(Box<dynamic> box, String gameId) {
    box.delete(gameId);
    box.delete(gameId + _suffixTileMapByRegion);
    box.delete(gameId + _suffixTopologyByRegion);
    box.delete(gameId + _suffixCombinedTopology);
    box.delete(gameId + _suffixWarpLinks);
  }
}
