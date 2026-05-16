import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:run_observer_game/observer_session_runner.dart';
import 'package:run_observer_game/run_observer_game_cli.dart';

void main() {
  group('runObserverGameCli', () {
    test('help exits 0 and mentions melos', () async {
      final out = <String>[];
      final err = <String>[];
      final code = await runObserverGameCli(
        ['--help'],
        emitStdout: out.add,
        emitStderr: err.add,
      );
      expect(code, 0);
      expect(err, isEmpty);
      expect(out.join('\n'), contains('melos run run_observer_game'));
      expect(out.join('\n'), contains('--output'));
    });

    test('parse failure yields EX_USAGE', () async {
      final out = <String>[];
      final err = <String>[];
      final code = await runObserverGameCli(
        ['--not-a-flag'],
        emitStdout: out.add,
        emitStderr: err.add,
      );
      expect(code, kExitUsage);
      expect(out, isEmpty);
      expect(err, isNotEmpty);
    });

    test('requires --output for non-help', () async {
      final out = <String>[];
      final err = <String>[];
      final code = await runObserverGameCli(
        ['--seed', '1'],
        emitStdout: out.add,
        emitStderr: err.add,
      );
      expect(code, kExitUsage);
      expect(out, isEmpty);
      expect(err.join('\n'), contains('--output'));
    });

    test('invalid --seed yields EX_USAGE', () async {
      final out = <String>[];
      final err = <String>[];
      final tmp = Directory.systemTemp.createTempSync('roc_seed_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final code = await runObserverGameCli(
        ['--output', tmp.path, '--seed', 'not-int'],
        emitStdout: out.add,
        emitStderr: err.add,
      );
      expect(code, kExitUsage);
      expect(err.join('\n'), contains('integer'));
    });

    test('negative --max-turns yields EX_USAGE', () async {
      final out = <String>[];
      final err = <String>[];
      final tmp = Directory.systemTemp.createTempSync('roc_max_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final code = await runObserverGameCli(
        ['--output', tmp.path, '--max-turns', '-1'],
        emitStdout: out.add,
        emitStderr: err.add,
      );
      expect(code, kExitUsage);
    });

    test('missing --config file yields EX_USAGE', () async {
      final out = <String>[];
      final err = <String>[];
      final tmp = Directory.systemTemp.createTempSync('roc_cfg_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final code = await runObserverGameCli(
        [
          '--output',
          tmp.path,
          '--config',
          '${tmp.path}/nope.json',
        ],
        emitStdout: out.add,
        emitStderr: err.add,
      );
      expect(code, kExitUsage);
      expect(err.join('\n'), isNotEmpty);
    });
  });

  group('observer session (smoke)', () {
    test(
      'max-turns zero writes run-summary.json only',
      () async {
        final tmp = Directory.systemTemp.createTempSync('run_observer_smoke_');
        addTearDown(() => tmp.deleteSync(recursive: true));

        final setup = GameSetupConfig(
          selectedGreatPowerIds: const ['england', 'france'],
          continentCount: 4,
          minorNationCount: 2,
          tribeCount: 2,
          numProvincesOldWorld: 14,
          numProvincesNewWorld: 6,
          minProvincesPerMinor: 2,
          seed: 11,
        );

        final code = await runObserverSession(
          outputRoot: tmp.path,
          setupConfig: setup,
          maxTurnsCap: 0,
        );

        expect(code, 0);

        final traceRoot = Directory('${tmp.path}/observer-traces');
        expect(traceRoot.existsSync(), isTrue);
        final summaryFiles = traceRoot
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('run-summary.json'))
            .toList();
        expect(summaryFiles, hasLength(1));
        final decoded =
            jsonDecode(summaryFiles.first.readAsStringSync())
                as Map<String, Object?>;

        expect(decoded['termination_reason'], 'max_turns_override');
        expect(decoded['resolved_full_turns'], 0);
      },
      timeout: const Timeout(Duration(minutes: 15)),
    );

    test(
      'max-turns one writes merged trace, snapshot, html, and summary',
      () async {
        final tmp = Directory.systemTemp.createTempSync('run_observer_one_');
        addTearDown(() => tmp.deleteSync(recursive: true));

        final setup = GameSetupConfig(
          selectedGreatPowerIds: const ['england', 'france'],
          continentCount: 4,
          minorNationCount: 2,
          tribeCount: 2,
          numProvincesOldWorld: 14,
          numProvincesNewWorld: 6,
          minProvincesPerMinor: 2,
          seed: 11,
        );

        final code = await runObserverSession(
          outputRoot: tmp.path,
          setupConfig: setup,
          maxTurnsCap: 1,
        );

        expect(code, 0);

        final observerRoot = Directory('${tmp.path}/observer-traces');
        expect(observerRoot.existsSync(), isTrue);
        final gameDirs = observerRoot.listSync().whereType<Directory>().toList();
        expect(gameDirs, hasLength(1));

        final gameDir = gameDirs.first;
        final names =
            gameDir.listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toList();

        expect(names.where((n) => n.endsWith('.snapshot.json')).length, 1);
        expect(names.where((n) => n.endsWith('.html')).length, 1);
        expect(
          names.where(
            (n) =>
                n.endsWith('.json') &&
                !n.endsWith('.snapshot.json') &&
                n != 'run-summary.json',
          ),
          isNotEmpty,
        );

        final summaryFile = File('${gameDir.path}/run-summary.json');
        expect(summaryFile.existsSync(), isTrue);
        final sum =
            jsonDecode(summaryFile.readAsStringSync()) as Map<String, Object?>;
        expect(sum['termination_reason'], 'max_turns_override');
        expect(sum['resolved_full_turns'], 1);
      },
      timeout: const Timeout(Duration(minutes: 15)),
    );
  });
}
