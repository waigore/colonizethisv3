// ignore_for_file: avoid_print
/// CLI: run game creation (map gen, province/capital assignment), export PNG and markdown.
/// SPEC/program/init-game-tool.md. Thin facade over colonizethis_logic.
/// Operational/diagnostic output via logger (SPEC/program/ctdev-logging.md); usage/help to stdout.
import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:init_game/package_logger.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:hive/hive.dart';

final _log = packageLogger('init_game');

Future<void> main(List<String> arguments) async {
  String? configPath;
  String? outputMapPath;
  String? outputMarkdownPath;
  String? outputGamePath;
  var noSave = false;
  int? seedOverride;
  List<String>? greatPowersOverride;
  int? greatPowerCount;
  int? minorNationCount;
  int? tribeCount;
  int? numProvincesOldWorld;
  int? numProvincesNewWorld;
  String? prussiaLeaderOverride;
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
        stderr.writeln('Error: --seed requires an integer');
        exit(1);
      }
      seedOverride = v;
    } else if (arg.startsWith('--seed=')) {
      final v = int.tryParse(arg.substring(7).trim());
      if (v == null) {
        stderr.writeln('Error: --seed requires an integer');
        exit(1);
      }
      seedOverride = v;
    } else if (arg == '--great-powers' && i + 1 < arguments.length) {
      greatPowersOverride = arguments[++i]
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (arg.startsWith('--great-powers=')) {
      greatPowersOverride = arg
          .substring('--great-powers='.length)
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (arg == '--great-power-count' && i + 1 < arguments.length) {
      greatPowerCount = int.tryParse(arguments[++i]);
    } else if (arg.startsWith('--great-power-count=')) {
      greatPowerCount = int.tryParse(
        arg.substring('--great-power-count='.length).trim(),
      );
    } else if (arg == '--minor-nation-count' && i + 1 < arguments.length) {
      minorNationCount = int.tryParse(arguments[++i]);
    } else if (arg.startsWith('--minor-nation-count=')) {
      minorNationCount = int.tryParse(
        arg.substring('--minor-nation-count='.length).trim(),
      );
    } else if (arg == '--tribe-count' && i + 1 < arguments.length) {
      tribeCount = int.tryParse(arguments[++i]);
    } else if (arg.startsWith('--tribe-count=')) {
      tribeCount = int.tryParse(arg.substring('--tribe-count='.length).trim());
    } else if (arg == '--num-provinces-old-world' && i + 1 < arguments.length) {
      numProvincesOldWorld = int.tryParse(arguments[++i]);
    } else if (arg.startsWith('--num-provinces-old-world=')) {
      numProvincesOldWorld = int.tryParse(
        arg.substring('--num-provinces-old-world='.length).trim(),
      );
    } else if (arg == '--num-provinces-new-world' && i + 1 < arguments.length) {
      numProvincesNewWorld = int.tryParse(arguments[++i]);
    } else if (arg.startsWith('--num-provinces-new-world=')) {
      numProvincesNewWorld = int.tryParse(
        arg.substring('--num-provinces-new-world='.length).trim(),
      );
    } else if (arg == '--prussia-leader' && i + 1 < arguments.length) {
      prussiaLeaderOverride = arguments[++i].trim();
    } else if (arg.startsWith('--prussia-leader=')) {
      prussiaLeaderOverride = arg.substring('--prussia-leader='.length).trim();
    }
  }

  var config = GameSetupConfig.defaultConfig;
  if (configPath != null && configPath.isNotEmpty) {
    final f = File(configPath);
    if (!f.existsSync()) {
      stderr.writeln('Error: config file not found: $configPath');
      exit(1);
    }
    final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    List<String> selectedIds = config.selectedGreatPowerIds;
    final jsonSelected = json['selectedGreatPowerIds'];
    if (jsonSelected is List) {
      selectedIds = jsonSelected.map((e) => e.toString()).toList();
    } else {
      final count = (json['greatPowerCount'] as num?)?.toInt();
      if (count != null && count > 0) {
        selectedIds = allGreatPowerIds.take(count).toList();
      }
    }
    Map<String, String> leaderVariantByGpId = config.leaderVariantByGpId;
    final jsonLeader = json['leaderVariantByGpId'];
    if (jsonLeader is Map) {
      leaderVariantByGpId = Map<String, String>.from(
        jsonLeader.map((k, v) => MapEntry(k.toString(), v.toString())),
      );
    }
    config = GameSetupConfig(
      selectedGreatPowerIds: selectedIds,
      leaderVariantByGpId: leaderVariantByGpId,
      continentCount:
          (json['continentCount'] as num?)?.toInt() ?? config.continentCount,
      minorNationCount:
          (json['minorNationCount'] as num?)?.toInt() ??
          config.minorNationCount,
      tribeCount: (json['tribeCount'] as num?)?.toInt() ?? config.tribeCount,
      numProvincesOldWorld:
          (json['numProvincesOldWorld'] as num?)?.toInt() ??
          config.numProvincesOldWorld,
      numProvincesNewWorld:
          (json['numProvincesNewWorld'] as num?)?.toInt() ??
          config.numProvincesNewWorld,
      seed: (json['seed'] as num?)?.toInt() ?? config.seed,
      initTownRoadWiringRegionIds:
          json['initTownRoadWiringRegionIds'] is List<dynamic>
          ? (json['initTownRoadWiringRegionIds'] as List<dynamic>)
                .map((e) => e.toString())
                .toSet()
          : config.initTownRoadWiringRegionIds,
    );
  }

  if (seedOverride != null) {
    config = GameSetupConfig(
      selectedGreatPowerIds: config.selectedGreatPowerIds,
      leaderVariantByGpId: config.leaderVariantByGpId,
      continentCount: config.continentCount,
      minorNationCount: config.minorNationCount,
      tribeCount: config.tribeCount,
      numProvincesOldWorld: config.numProvincesOldWorld,
      numProvincesNewWorld: config.numProvincesNewWorld,
      seed: seedOverride,
      initTownRoadWiringRegionIds: config.initTownRoadWiringRegionIds,
    );
  }
  if (greatPowersOverride != null ||
      greatPowerCount != null ||
      minorNationCount != null ||
      tribeCount != null ||
      numProvincesOldWorld != null ||
      numProvincesNewWorld != null) {
    List<String> selectedIds = config.selectedGreatPowerIds;
    if (greatPowersOverride != null && greatPowersOverride.isNotEmpty) {
      selectedIds = greatPowersOverride;
    } else if (greatPowerCount != null && greatPowerCount > 0) {
      selectedIds = allGreatPowerIds.take(greatPowerCount).toList();
    }
    Map<String, String> leaderVariantByGpId = config.leaderVariantByGpId;
    if (prussiaLeaderOverride != null && selectedIds.contains('prussia')) {
      if (prussiaLeaderOverride == prussiaVariantFrederickTheGreat ||
          prussiaLeaderOverride == prussiaVariantFrederickWilliam) {
        leaderVariantByGpId = {
          ...leaderVariantByGpId,
          'prussia': prussiaLeaderOverride,
        };
      } else {
        stderr.writeln(
          'Error: --prussia-leader must be $prussiaVariantFrederickTheGreat or $prussiaVariantFrederickWilliam',
        );
        exit(1);
      }
    }
    config = GameSetupConfig(
      selectedGreatPowerIds: selectedIds,
      leaderVariantByGpId: leaderVariantByGpId,
      continentCount: config.continentCount,
      minorNationCount: minorNationCount ?? config.minorNationCount,
      tribeCount: tribeCount ?? config.tribeCount,
      numProvincesOldWorld: numProvincesOldWorld ?? config.numProvincesOldWorld,
      numProvincesNewWorld: numProvincesNewWorld ?? config.numProvincesNewWorld,
      seed: config.seed,
      initTownRoadWiringRegionIds: config.initTownRoadWiringRegionIds,
    );
  }

  try {
    _log.i('start');
    _log.i('Running game setup...');
    final shouldRenderPng = outputMapPath != null && outputMapPath.isNotEmpty;
    final result = runInitGame(
      config: config,
      options: InitGameOptions(cellSize: 24, renderPng: shouldRenderPng),
    );
    _log.i('Game created: ${result.game.id}');

    if (outputMapPath != null && outputMapPath.isNotEmpty) {
      File(outputMapPath).writeAsBytesSync(result.mapPngBytes);
      _log.d('Map PNG: $outputMapPath');
    }

    if (outputMarkdownPath != null && outputMarkdownPath.isNotEmpty) {
      File(outputMarkdownPath).writeAsStringSync(result.markdown);
      _log.d('Markdown: $outputMarkdownPath');
    }

    if (!noSave && outputGamePath != null && outputGamePath.isNotEmpty) {
      await _saveGame(result.game, outputGamePath);
      _log.d('Game saved: $outputGamePath');
    }

    _log.i('Faction setup:\n${result.markdown}');
  } catch (e) {
    final message = e is ArgumentError
        ? (e.message ?? e.toString())
        : 'Game setup failed: $e';
    stderr.writeln('Error: $message');
    exit(1);
  }
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
  // Usage/help to stdout per CLI contract (SPEC/program/init-game-tool.md).
  print('Usage:');
  print('  melos run init_game -- [options]');
  print('');
  print(
    'Runs game creation (map gen, province/capital assignment), exports map PNG and faction setup markdown.',
  );
  print('');
  print('Options:');
  print('  --config <path>         JSON config (optional)');
  print('  --output-map <path>     Write map PNG');
  print('  --output-markdown <path>  Write faction setup markdown');
  print(
    '  --output-game <path>    Save game to path when set (unless --no-save)',
  );
  print('  --no-save               Do not save game');
  print('  --seed <n>              RNG seed');
  print(
    '  --great-powers id1,id2  Comma-separated Great Power ids (e.g. england,france,spain)',
  );
  print(
    '  --great-power-count N   Override: use first N powers from default order (backward compat)',
  );
  print(
    '  --prussia-leader ID     When prussia is selected: frederick_the_great | frederick_william (default: first)',
  );
  print('  --minor-nation-count N  Override config');
  print('  --tribe-count N         Override config');
  print('  --num-provinces-old-world N  Override config');
  print('  --num-provinces-new-world N  Override config');
}
