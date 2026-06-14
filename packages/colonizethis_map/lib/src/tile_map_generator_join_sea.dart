/// Pass 10–11: join continents, terrain jitter, sea subdivision.

part of 'tile_map_generator.dart';

class _TileMapGenJoinSea implements MapGenStage {
  _TileMapGenJoinSea(this.params, this._log, this._graph);

  @override
  final TileMapParams params;
  final CtLogger _log;
  final TileMapGridGraph _graph;
}
