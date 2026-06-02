import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:run_observer_game/observer_minimal_trace.dart';
import 'package:run_observer_game/observer_session_runner.dart';
import 'package:run_observer_game/observer_workforce_verify.dart';
import 'package:run_observer_game/run_observer_game_cli.dart';

/// Decodes `<pre>` text produced by `HtmlEscape` (snapshot HTML wrapper).
String _decodedPreBodyFromObserverHtml(String html) {
  final m = RegExp(r'<pre>([\s\S]*?)</pre>').firstMatch(html);
  expect(m, isNotNull);
  var s = m!.group(1)!;
  s = s
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&#x27;', "'");
  return s;
}

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

    test('verify-colonial-expansion with low max-turns yields EX_USAGE', () async {
      final out = <String>[];
      final err = <String>[];
      final tmp = Directory.systemTemp.createTempSync('roc_colonial_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final code = await runObserverGameCli(
        ['--output', tmp.path, '--max-turns', '100', '--verify-colonial-expansion'],
        emitStdout: out.add,
        emitStderr: err.add,
      );
      expect(code, kExitUsage);
      expect(err.join('\n'), contains('verify-colonial-expansion'));
    });

    test('verify-conquest with low max-turns yields EX_USAGE', () async {
      final out = <String>[];
      final err = <String>[];
      final tmp = Directory.systemTemp.createTempSync('roc_verify_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final code = await runObserverGameCli(
        ['--output', tmp.path, '--max-turns', '30', '--verify-conquest'],
        emitStdout: out.add,
        emitStderr: err.add,
      );
      expect(code, kExitUsage);
      expect(err.join('\n'), contains('verify-conquest'));
    });

    test('verify-workforce with low max-turns yields EX_USAGE', () async {
      final out = <String>[];
      final err = <String>[];
      final tmp = Directory.systemTemp.createTempSync('roc_workforce_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final code = await runObserverGameCli(
        [
          '--output',
          tmp.path,
          '--max-turns',
          '50',
          '--verify-workforce',
        ],
        emitStdout: out.add,
        emitStderr: err.add,
      );
      expect(code, kExitUsage);
      final stderr = err.join('\n');
      expect(stderr, contains('--verify-workforce'));
      expect(
        stderr,
        contains('$kObserverWorkforceCanonicalTurn'),
        reason:
            'CLI usage error must surface the canonical workforce turn so '
            'callers can fix --max-turns without spelunking SPEC.',
      );
    });

    test('--help mentions --verify-workforce', () async {
      final out = <String>[];
      final err = <String>[];
      final code = await runObserverGameCli(
        ['--help'],
        emitStdout: out.add,
        emitStderr: err.add,
      );
      expect(code, 0);
      expect(err, isEmpty);
      expect(out.join('\n'), contains('verify-workforce'));
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

        final snapshotPath = names.firstWhere(
          (n) => n.endsWith('.snapshot.json'),
        );
        final htmlPath = names.firstWhere((n) => n.endsWith('.html'));
        final snapshotText = File('${gameDir.path}/$snapshotPath')
            .readAsStringSync();
        final htmlText = File('${gameDir.path}/$htmlPath').readAsStringSync();
        final fromHtml = _decodedPreBodyFromObserverHtml(htmlText).trimRight();
        expect(
          jsonDecode(fromHtml),
          jsonDecode(snapshotText.trimRight()),
          reason: 'HTML <pre> must render the same canonical JSON as the snapshot file',
        );
      },
      timeout: const Timeout(Duration(minutes: 15)),
    );

    test(
      'minimal trace mode skips merged traces and html',
      () async {
        final tmp = Directory.systemTemp.createTempSync('run_observer_min_');
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
          verifyConquest: true,
          verifyColonialExpansion: true,
        );

        expect(code, 0);

        final gameDir = Directory('${tmp.path}/observer-traces')
            .listSync()
            .whereType<Directory>()
            .single;
        final names =
            gameDir.listSync().whereType<File>().map((f) => f.uri.pathSegments.last).toList()
              ..sort();

        expect(names, ['run-summary.json', 'turn-000001.snapshot.json']);
        expect(names.where((n) => n.endsWith('.html')), isEmpty);
        expect(
          names.where(
            (n) =>
                n.endsWith('.json') &&
                !n.endsWith('.snapshot.json') &&
                n != 'run-summary.json',
          ),
          isEmpty,
        );

        final summary =
            jsonDecode(File('${gameDir.path}/run-summary.json').readAsStringSync())
                as Map<String, Object?>;
        expect(summary['minimal_trace_mode'], isTrue);

        var totalBytes = 0;
        for (final f in gameDir.listSync().whereType<File>()) {
          totalBytes += f.lengthSync();
        }
        expect(totalBytes, lessThan(kObserverVerifyArtifactSizeCapBytes));
      },
      timeout: const Timeout(Duration(minutes: 15)),
    );

    test(
      'minimal trace mode exits 7 when artifact cap exceeded',
      () async {
        final tmp = Directory.systemTemp.createTempSync('run_observer_cap_');
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
          verifyConquest: true,
          verifyArtifactCapBytes: 1,
        );

        expect(code, kExitArtifactSizeCapExceeded);
      },
      timeout: const Timeout(Duration(minutes: 15)),
    );

    test(
      'minimal trace mode honours verifyWorkforce union (turn-100 snapshot)',
      () async {
        final tmp = Directory.systemTemp.createTempSync('run_observer_wf_');
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
          verifyWorkforce: true,
        );

        expect(code, 0);

        final gameDir = Directory('${tmp.path}/observer-traces')
            .listSync()
            .whereType<Directory>()
            .single;
        final names = gameDir
            .listSync()
            .whereType<File>()
            .map((f) => f.uri.pathSegments.last)
            .toList()
          ..sort();

        expect(
          names,
          ['run-summary.json'],
          reason:
              '--verify-workforce + maxTurns=1 must not produce a turn-1 '
              'snapshot (workforce only needs turn 100). The session ends '
              'before turn 100 so no snapshot is written; only '
              'run-summary.json remains.',
        );
        expect(names.where((n) => n.endsWith('.html')), isEmpty);

        final summary = jsonDecode(
              File('${gameDir.path}/run-summary.json').readAsStringSync(),
            ) as Map<String, Object?>;
        expect(summary['minimal_trace_mode'], isTrue);

        final failures = verifyObserverWorkforceFromTraceDir(gameDir.path);
        expect(failures, hasLength(1));
        expect(failures.single, contains('missing end snapshot'));
      },
      timeout: const Timeout(Duration(minutes: 15)),
    );
  });
}
