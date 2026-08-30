import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:hive/hive.dart';

/// Cached map data for a game (topology and tile maps for turn resolution).
class GameMapCache {
  GameMapCache({
    required this.combinedTopology,
    required this.tileMapByRegion,
    required this.topologyByRegion,
    this.warpLinks,
  });
  final MapTopology combinedTopology;
  final Map<String, TileMapResult> tileMapByRegion;
  final Map<String, MapTopology> topologyByRegion;
  final List<WarpLink>? warpLinks;
}

/// In-memory turn-trace session state for one game id.
class TurnTraceSession {
  TurnTraceSession({required this.startedAtUtc});
  final DateTime startedAtUtc;
  final List<TurnTracePhaseTrace> phases = <TurnTracePhaseTrace>[];
  final TurnTraceRuntime turnTraceRuntime = TurnTraceRuntime();
  List<TurnTraceAiSection>? aiTraceSections;
}

/// Mutable session state shared by [GameService] implementation libraries.
class GameServiceState {
  GameServiceState({
    required this.box,
    required this.adapter,
    required this.turnTraceEnabled,
    required this.turnTraceRootDirectory,
  });
  final Box<dynamic> box;
  final GameSaveAdapter adapter;
  final bool turnTraceEnabled;
  final String turnTraceRootDirectory;
  final Map<String, GameMapCache> mapCache = <String, GameMapCache>{};
  final Map<String, TurnTraceSession> turnTraceSessionsByGameId =
      <String, TurnTraceSession>{};
}

/// Public record type for [GameService.getMapData] (Refs #2575 Phase 4).
/// Lets callers replace `dynamic` with an explicit type while still using
/// record-style access (`mapData.combinedTopology`, etc.).
typedef GameMapData = ({
  MapTopology combinedTopology,
  Map<String, TileMapResult> tileMapByRegion,
  Map<String, MapTopology> topologyByRegion,
  List<WarpLink>? warpLinks,
});
