// init_game orchestration. SPEC/program/init-game-tool.md.

import 'dart:typed_data';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'game_setup.dart';

/// Result of running init game.
class InitGameResult {
  const InitGameResult({
    required this.game,
    required this.mapPngBytes,
    required this.markdown,
    required this.mapViewData,
  });

  final Game game;
  final Uint8List mapPngBytes;
  final String markdown;
  final InitGameMapViewData mapViewData;
}

/// Options for runInitGame.
class InitGameOptions {
  const InitGameOptions({
    this.cellSize = 24,
  });

  final int cellSize;
}

/// Runs the full game creation process: generate OW+NW maps, create game, render map, format markdown.
/// Returns InitGameResult; does not save the game.
InitGameResult runInitGame({
  required GameSetupConfig config,
  InitGameOptions options = const InitGameOptions(),
}) {
  final mapGenParams = MapGenerationParams(
    numContinents: config.continentCount,
    seed: config.seed,
    seaFraction: 0.6,
  );
  final sizeOW = computeGridSizeFromParams(config.numProvincesOldWorld, mapGenParams);
  final paramsOW = TileMapParams(
    width: sizeOW.width,
    height: sizeOW.height,
    seed: config.seed,
    seaFraction: 0.6,
  );
  final (tileMapOW, topoOW) = TileMapGenerator(params: paramsOW).generate(
    numProvinces: config.numProvincesOldWorld,
    numContinents: config.continentCount,
    regionId: 'oldWorld',
  );

  final sizeNW = computeGridSizeFromParams(config.numProvincesNewWorld, mapGenParams);
  final paramsNW = TileMapParams(
    width: sizeNW.width,
    height: sizeNW.height,
    seed: config.seed + 1,
    seaFraction: 0.6,
  );
  final (tileMapNW, topoNW) = TileMapGenerator(params: paramsNW).generate(
    numProvinces: config.numProvincesNewWorld,
    numContinents: config.continentCount.clamp(1, config.numProvincesNewWorld),
    regionId: 'newWorld',
  );

  final setupResult = createGameFromGeneratedMaps(
    config: config,
    tileMapOldWorld: tileMapOW,
    topologyOldWorld: topoOW,
    tileMapNewWorld: tileMapNW,
    topologyNewWorld: topoNW,
    gameId: 'game_${DateTime.now().millisecondsSinceEpoch}',
  );

  final mapViewData = buildInitGameMapViewData(
    game: setupResult.game,
    tileMapByRegion: setupResult.tileMapByRegion,
    topologyByRegion: setupResult.topologyByRegion,
    cellSize: options.cellSize,
    seed: config.seed,
    configSummary:
        'GP:${config.greatPowerCount} MN:${config.minorNationCount} TR:${config.tribeCount} OW:${config.numProvincesOldWorld} NW:${config.numProvincesNewWorld}',
  );

  final mapPngBytes = renderInitGameMapToPngFromViewData(
    viewData: mapViewData,
  );

  final markdown = formatInitGameSetupMarkdown(setupResult.game);

  return InitGameResult(
    game: setupResult.game,
    mapPngBytes: mapPngBytes,
    markdown: markdown,
    mapViewData: mapViewData,
  );
}

/// Formats faction setup and starting state as markdown tables.
String formatInitGameSetupMarkdown(Game game) {
  final buf = StringBuffer();
  buf.writeln('# Game Setup');
  buf.writeln();
  buf.writeln('## Faction Setup');
  buf.writeln();
  buf.writeln('| Faction | Type | Capital Province | Provinces Owned |');
  buf.writeln('|---------|------|------------------|-----------------|');

  for (final p in game.players) {
    final owned = game.worldState.oldWorld.provinces
        .where((pr) => pr.ownerId == p.id)
        .map((pr) => pr.id)
        .toList()
      ..sort();
    final capital = p.capitalProvinceId ?? '—';
    buf.writeln('| ${p.displayName} (${p.id}) | Great Power | $capital | ${owned.join(", ")} |');
  }
  for (final m in game.minorNations) {
    final owned = game.worldState.oldWorld.provinces
        .where((pr) => pr.ownerId == m.id)
        .map((pr) => pr.id)
        .toList()
      ..sort();
    final capital = m.capitalProvinceId ?? '—';
    buf.writeln('| ${m.displayName ?? m.id} (${m.id}) | Minor Nation | $capital | ${owned.join(", ")} |');
  }
  for (final t in game.tribes) {
    final owned = game.worldState.newWorld.provinces
        .where((pr) => pr.ownerId == t.id)
        .map((pr) => pr.id)
        .toList()
      ..sort();
    final capital = t.capitalProvinceId ?? '—';
    buf.writeln('| ${t.displayName ?? t.id} (${t.id}) | Tribe | $capital | ${owned.join(", ")} |');
  }

  buf.writeln();
  buf.writeln('## Faction Starting State');
  buf.writeln();
  buf.writeln('| Faction | Stockpile | Workers | Treasury | Units |');
  buf.writeln('|---------|-----------|---------|----------|-------|');

  for (final p in game.players) {
    final stock = p.stockpile.quantities.entries
        .where((e) => e.value > 0)
        .map((e) => '${e.key}:${e.value}')
        .join(', ');
    final workers = '${p.workerPool.peasants}p/${p.workerPool.apprentices}a/${p.workerPool.journeymen}j/${p.workerPool.masters}m';
    final units = game.worldState.oldWorld.units
            .where((u) => u.ownerId == p.id)
            .length +
        game.worldState.newWorld.units.where((u) => u.ownerId == p.id).length;
    buf.writeln('| ${p.displayName} (${p.id}) | ${stock.isEmpty ? "—" : stock} | $workers | ${p.treasury} | $units |');
  }
  for (final m in game.minorNations) {
    buf.writeln('| ${m.displayName ?? m.id} (${m.id}) | — | — | — | — |');
  }
  for (final t in game.tribes) {
    buf.writeln('| ${t.displayName ?? t.id} (${t.id}) | — | — | — | — |');
  }

  return buf.toString();
}
