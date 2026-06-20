/// Pass 10–11: join continents, terrain jitter, sea subdivision.

part of 'tile_map_generator.dart';

/// Exempt from the uniform [MapGenPass] entry point (Refs #3574, slice 4):
/// this family owns three heterogeneous passes — continent joining
/// (grid+terrain+resource in/out), terrain jitter (in-place mutation), and
/// sea-zone subdivision (grid in/out) — that share no single representative
/// payload/result shape. It therefore implements [MapGenStage] only; the
/// orchestrator drives its three passes via their dedicated methods.
class _TileMapGenJoinSea implements MapGenStage {
  _TileMapGenJoinSea(this.params, this._log, this._graph);

  @override
  final TileMapParams params;
  final CtLogger _log;
  final TileMapGridGraph _graph;
}
