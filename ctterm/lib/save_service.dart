// Ctterm save/load: Hive box in ctterm-specific directory. SPEC/tui/ctterm.md §5, SPEC/program/save-load.md.

import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart' as log_pkg;
import 'package:path/path.dart' as path;

final log_pkg.Logger _log = log_pkg.Logger();

String? _initDataDir;
Box<dynamic>? _box;

/// Returns the ctterm data directory. Uses [override] if provided; otherwise
/// $HOME/.colonizethis_ctterm (or $XDG_DATA_HOME/colonizethis_ctterm on Linux when set).
String getCttermDataDir([String? override]) {
  if (override != null && override.isNotEmpty) return override;
  if (_initDataDir != null) return _initDataDir!;
  final env = Platform.environment;
  if (Platform.isLinux && env.containsKey('XDG_DATA_HOME')) {
    _initDataDir = path.join(env['XDG_DATA_HOME']!, 'colonizethis_ctterm');
  } else {
    final home = env['HOME'] ?? env['USERPROFILE'] ?? '.';
    _initDataDir = path.join(home, '.colonizethis_ctterm');
  }
  return _initDataDir!;
}

/// Ensures Hive is initialized and the games box is open. Call before list/load/save.
Future<Box<dynamic>> _ensureBox([String? dataDirOverride]) async {
  if (_box != null && _box!.isOpen) return _box!;
  final dir = getCttermDataDir(dataDirOverride);
  final dirFile = Directory(dir);
  if (!dirFile.existsSync()) {
    dirFile.createSync(recursive: true);
  }
  Hive.init(dir);
  _box = await Hive.openBox<dynamic>('games');
  _log.d('tui:save: Hive box opened at $dir');
  return _box!;
}

final _adapter = GameSaveAdapter();

/// Lists stored game ids. [dataDirOverride] overrides the default data directory.
/// Returns [] if box not yet opened or empty.
Future<List<String>> listGameIds([String? dataDirOverride]) async {
  final box = await _ensureBox(dataDirOverride);
  final ids = _adapter.listGameIds(box);
  _log.d('tui:save: listGameIds count=${ids.length}');
  return ids;
}

/// Loads game by id. Returns null if not found or invalid.
Future<Game?> loadGame(String gameId, [String? dataDirOverride]) async {
  final box = await _ensureBox(dataDirOverride);
  return _adapter.load(box, gameId);
}

/// Loads map data for [gameId]. Returns null for legacy saves (no map data stored).
Future<({
  Map<String, TileMapResult> tileMapByRegion,
  Map<String, MapTopology> topologyByRegion,
  MapTopology combinedTopology,
})?> loadMapData(String gameId, [String? dataDirOverride]) async {
  final box = await _ensureBox(dataDirOverride);
  return _adapter.loadMapData(box, gameId);
}

/// Saves [game] and optional [result] map data.
Future<void> saveGameAndMapData(
  Game game,
  InitGameResult result, [
  String? dataDirOverride,
]) async {
  final box = await _ensureBox(dataDirOverride);
  _adapter.save(box, game);
  _adapter.saveMapData(
    box,
    game.id,
    tileMapByRegion: result.tileMapByRegion,
    topologyByRegion: result.topologyByRegion,
    combinedTopology: result.combinedTopology,
  );
  _log.i('tui:save: saved gameId=${game.id} with map data');
}

/// Summary of a saved game for display in Load Game list.
class SaveSummary {
  const SaveSummary({
    required this.gameId,
    required this.turnNumber,
    required this.year,
    required this.humanPlayerName,
    this.lastPlayedAt,
  });

  final String gameId;
  final int turnNumber;
  final int year;
  final String humanPlayerName;
  final DateTime? lastPlayedAt;
}

/// Lists saved games with metadata. Returns empty list if none or on error.
Future<List<SaveSummary>> listSaves([String? dataDirOverride]) async {
  final box = await _ensureBox(dataDirOverride);
  final ids = _adapter.listGameIds(box);
  if (ids.isEmpty) return [];

  final summaries = <SaveSummary>[];
  for (final id in ids) {
    final game = _adapter.load(box, id);
    if (game == null) continue;

    // Get human player name (first player is human)
    String humanName = 'Unknown';
    if (game.players.isNotEmpty) {
      humanName = game.players.first.displayName;
    }

    // Calculate year from turn (default mapping: turn 0 = 1600)
    final year = 1600 + (game.worldState.turnState.turnNumber ~/ 2);

    summaries.add(SaveSummary(
      gameId: id,
      turnNumber: game.worldState.turnState.turnNumber,
      year: year,
      humanPlayerName: humanName,
    ));
  }

  // Sort by turn number descending (most recent first)
  summaries.sort((a, b) => b.turnNumber.compareTo(a.turnNumber));

  _log.d('tui:save: listSaves count=${summaries.length}');
  return summaries;
}

/// Deletes a saved game by id.
Future<void> deleteSave(String gameId, [String? dataDirOverride]) async {
  final box = await _ensureBox(dataDirOverride);
  _adapter.delete(box, gameId);
  _log.i('tui:save: deleted gameId=$gameId');
}
