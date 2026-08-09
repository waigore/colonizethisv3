// Ctdev save/load: Hive box and GameSaveAdapter. SPEC/program/ctdev-app.md, SPEC/program/save-load.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:ctdev/package_logger.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

final _log = packageLogger('save');

Box<dynamic>? _box;

/// Ensures Hive is initialized and the games box is open. Call before list/load/save.
Future<Box<dynamic>> _ensureBox() async {
  if (_box != null && _box!.isOpen) return _box!;
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
  _box = await Hive.openBox<dynamic>('games');
  _log.d('Hive box opened at ${dir.path}');
  return _box!;
}

final _adapter = GameSaveAdapter();

/// Lists stored game ids. Returns [] if box not yet opened or empty.
Future<List<String>> listGameIds() async {
  final box = await _ensureBox();
  final ids = _adapter.listGameIds(box);
  _log.d('listGameIds count=${ids.length}');
  return ids;
}

/// Loads game by id. Returns null if not found or invalid.
Future<Game?> loadGame(String gameId) async {
  final box = await _ensureBox();
  return _adapter.load(box, gameId);
}

/// Loads map data for [gameId]. Returns null for legacy saves (no map data stored).
Future<({
  Map<String, TileMapResult> tileMapByRegion,
  Map<String, MapTopology> topologyByRegion,
  MapTopology combinedTopology,
  List<WarpLink>? warpLinks,
})?> loadMapData(String gameId) async {
  final box = await _ensureBox();
  return _adapter.loadMapData(box, gameId);
}

/// Saves [game] and optional [result] map data so Load Savegame can show the map.
Future<void> saveGameAndMapData(Game game, InitGameResult result) async {
  final box = await _ensureBox();
  _adapter.save(box, game);
  _adapter.saveMapData(
    box,
    game.id,
    tileMapByRegion: result.tileMapByRegion,
    topologyByRegion: result.topologyByRegion,
    combinedTopology: result.combinedTopology,
  );
  _log.i('saved gameId=${game.id} with map data');
}
