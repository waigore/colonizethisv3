// ignore_for_file: avoid_print
/// CLI: run game creation (map gen, province/capital assignment), export PNG and markdown.
/// SPEC/program/init-game-tool.md. Thin facade over colonizethis_logic.
import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:hive/hive.dart';

Future<void> main(List<String> arguments) async {
  String? configPath;
  String? outputMapPath;
  String? outputMarkdownPath;
  String? outputGamePath;
  var noSave = false;
  int? seedOverride;
  int? greatPowerCount;
  int? minorNationCount;
  int? tribeCount;
  int? numProvincesOldWorld;
  int? numProvincesNewWorld;

  for (var i = 0; i < arguments.length; i++) {
    final arg = arguments[i];
    if (arg == '--help' || arg == '-h') {
      _printUsage();
      exit(0);
    }
    if (arg == '--config' && i + 1 < arguments.length) {
      configPath = arguments[++i];
    } else if (arg.startsWith('--config=')) {
      configPath = arg.substring(9).trim();
    } else if (arg == '--output-map' && i + 1 < arguments.length) {
      outputMapPath = arguments[++i];
    } else if (arg.startsWith('--output-map=')) {
      outputMapPath = arg.substring('--output-map='.length).trim();
    } else if (arg == '--output-markdown' && i + 1 < arguments.length) {
      outputMarkdownPath = arguments[++i];
    } else if (arg.startsWith('--output-markdown=')) {
      outputMarkdownPath = arg.substring('--output-markdown='.length).trim();
    } else if (arg == '--output-game' && i + 1 < arguments.length) {
      outputGamePath = arguments[++i];
    } else if (arg.startsWith('--output-game=')) {
      outputGamePath = arg.substring('--output-game='.length).trim();
    } else if (arg == '--no-save') {
      noSave = true;
    } else if (arg == '--seed' && i + 1 < arguments.length) {
      final v = int.tryParse(arguments[++i]);
      if (v == null) {
        print('Error: --seed requires an integer');
        exit(1);
      }
      seedOverride = v;
    } else if (arg.startsWith('--seed=')) {
      final v = int.tryParse(arg.substring(7).trim());
      if (v == null) {
        print('Error: --seed requires an integer');
        exit(1);
      }
      seedOverride = v;
    } else if (arg == '--great-power-count' && i + 1 < arguments.length) {
      greatPowerCount = int.tryParse(arguments[++i]);
    } else if (arg.startsWith('--great-power-count=')) {
      greatPowerCount = int.tryParse(arg.substring('--great-power-count='.length).trim());
    } else if (arg == '--minor-nation-count' && i + 1 < arguments.length) {
      minorNationCount = int.tryParse(arguments[++i]);
    } else if (arg.startsWith('--minor-nation-count=')) {
      minorNationCount = int.tryParse(arg.substring('--minor-nation-count='.length).trim());
    } else if (arg == '--tribe-count' && i + 1 < arguments.length) {
      tribeCount = int.tryParse(arguments[++i]);
    } else if (arg.startsWith('--tribe-count=')) {
      tribeCount = int.tryParse(arg.substring('--tribe-count='.length).trim());
    } else if (arg == '--num-provinces-old-world' && i + 1 < arguments.length) {
      numProvincesOldWorld = int.tryParse(arguments[++i]);
    } else if (arg.startsWith('--num-provinces-old-world=')) {
      numProvincesOldWorld = int.tryParse(arg.substring('--num-provinces-old-world='.length).trim());
    } else if (arg == '--num-provinces-new-world' && i + 1 < arguments.length) {
      numProvincesNewWorld = int.tryParse(arguments[++i]);
    } else if (arg.startsWith('--num-provinces-new-world=')) {
      numProvincesNewWorld = int.tryParse(arg.substring('--num-provinces-new-world='.length).trim());
    }
  }

  var config = GameSetupConfig.defaultConfig;
  if (configPath != null && configPath.isNotEmpty) {
    final f = File(configPath);
    if (!f.existsSync()) {
      print('Error: config file not found: $configPath');
      exit(1);
    }
    final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    config = GameSetupConfig(
      greatPowerCount: (json['greatPowerCount'] as num?)?.toInt() ?? config.greatPowerCount,
      continentCount: (json['continentCount'] as num?)?.toInt() ?? config.continentCount,
      minorNationCount: (json['minorNationCount'] as num?)?.toInt() ?? config.minorNationCount,
      tribeCount: (json['tribeCount'] as num?)?.toInt() ?? config.tribeCount,
      numProvincesOldWorld: (json['numProvincesOldWorld'] as num?)?.toInt() ?? config.numProvincesOldWorld,
      numProvincesNewWorld: (json['numProvincesNewWorld'] as num?)?.toInt() ?? config.numProvincesNewWorld,
      seed: (json['seed'] as num?)?.toInt() ?? config.seed,
    );
  }

  if (seedOverride != null) {
    config = GameSetupConfig(
      greatPowerCount: config.greatPowerCount,
      continentCount: config.continentCount,
      minorNationCount: config.minorNationCount,
      tribeCount: config.tribeCount,
      numProvincesOldWorld: config.numProvincesOldWorld,
      numProvincesNewWorld: config.numProvincesNewWorld,
      seed: seedOverride,
    );
  }
  if (greatPowerCount != null || minorNationCount != null || tribeCount != null ||
      numProvincesOldWorld != null || numProvincesNewWorld != null) {
    config = GameSetupConfig(
      greatPowerCount: greatPowerCount ?? config.greatPowerCount,
      continentCount: config.continentCount,
      minorNationCount: minorNationCount ?? config.minorNationCount,
      tribeCount: tribeCount ?? config.tribeCount,
      numProvincesOldWorld: numProvincesOldWorld ?? config.numProvincesOldWorld,
      numProvincesNewWorld: numProvincesNewWorld ?? config.numProvincesNewWorld,
      seed: config.seed,
    );
  }

  print('=== init_game ===');
  print('Running game setup...');
  final shouldRenderPng =
      outputMapPath != null && outputMapPath.isNotEmpty;
  final result = runInitGame(
    config: config,
    options: InitGameOptions(
      cellSize: 24,
      renderPng: shouldRenderPng,
    ),
  );
  print('Game created: ${result.game.id}');

  if (outputMapPath != null && outputMapPath.isNotEmpty) {
    File(outputMapPath).writeAsBytesSync(result.mapPngBytes);
    print('Map PNG: $outputMapPath');
  }

  if (outputMarkdownPath != null && outputMarkdownPath.isNotEmpty) {
    File(outputMarkdownPath).writeAsStringSync(result.markdown);
    print('Markdown: $outputMarkdownPath');
  }

  if (!noSave && outputGamePath != null && outputGamePath.isNotEmpty) {
    await _saveGame(result.game, outputGamePath);
    print('Game saved: $outputGamePath');
  }

  print('');
  print(result.markdown);
}

Future<void> _saveGame(Game game, String path) async {
  final dir = Directory(path);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  Hive.init(dir.absolute.path);
  final box = await Hive.openBox<dynamic>('games');
  try {
    GameSaveAdapter().save(box, game);
  } finally {
    await box.close();
  }
}

void _printUsage() {
  print('Usage:');
  print('  melos run init_game -- [options]');
  print('');
  print('Runs game creation (map gen, province/capital assignment), exports map PNG and faction setup markdown.');
  print('');
  print('Options:');
  print('  --config <path>         JSON config (optional)');
  print('  --output-map <path>     Write map PNG');
  print('  --output-markdown <path>  Write faction setup markdown');
  print('  --output-game <path>    Save game (requires --output-game when not --no-save)');
  print('  --no-save               Do not save game');
  print('  --seed <n>              RNG seed');
  print('  --great-power-count N   Override config');
  print('  --minor-nation-count N  Override config');
  print('  --tribe-count N         Override config');
  print('  --num-provinces-old-world N  Override config');
  print('  --num-provinces-new-world N  Override config');
}
