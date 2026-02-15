import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Package root: tool/generate_map. Works when run from package dir or repo root.
String get _packageRoot {
  final cwd = Directory.current.path;
  final inPackage = File(p.join(cwd, 'bin', 'generate_map.dart')).existsSync();
  return inPackage ? cwd : p.join(cwd, 'tool', 'generate_map');
}

void main() {
  group('generate_map CLI', () {
    test('end-to-end with explicit params produces topology graph and map summary', () async {
      final result = await Process.run(
        'dart',
        [
          'run',
          'generate_map',
          '--provinces',
          '4',
          '--continents',
          '2',
        ],
        runInShell: false,
        workingDirectory: _packageRoot,
      );
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(result.stdout, contains('=== Topology graph ==='));
      expect(result.stdout, contains('=== Map summary ==='));
      expect(result.stdout, contains('Generating map: 4 provinces, 2 continents'));
    });

    test('end-to-end with defaults (no args) produces topology and map', () async {
      final result = await Process.run(
        'dart',
        ['run', 'generate_map'],
        runInShell: false,
        workingDirectory: _packageRoot,
      );
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(result.stdout, contains('=== Topology graph ==='));
      expect(result.stdout, contains('=== Map summary ==='));
      expect(result.stdout, contains('Generating map: 60 provinces, 3 continents'));
    });

    test('--region newWorld is accepted', () async {
      final result = await Process.run(
        'dart',
        [
          'run',
          'generate_map',
          '--provinces',
          '2',
          '--continents',
          '2',
          '--region',
          'newWorld',
        ],
        runInShell: false,
        workingDirectory: _packageRoot,
      );
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(result.stdout, contains('region newWorld'));
    });

    test('--continents 1 exits with error', () async {
      final result = await Process.run(
        'dart',
        [
          'run',
          'generate_map',
          '--provinces',
          '5',
          '--continents',
          '1',
        ],
        runInShell: false,
        workingDirectory: _packageRoot,
      );
      expect(result.exitCode, 1);
      expect(result.stdout, contains('2–4'));
    });

    test('--continents 5 exits with error', () async {
      final result = await Process.run(
        'dart',
        [
          'run',
          'generate_map',
          '--provinces',
          '10',
          '--continents',
          '5',
        ],
        runInShell: false,
        workingDirectory: _packageRoot,
      );
      expect(result.exitCode, 1);
      expect(result.stdout, contains('2–4'));
    });

    test('--sea-fraction and --tiles-per-province run successfully', () async {
      final result = await Process.run(
        'dart',
        [
          'run',
          'generate_map',
          '--provinces',
          '4',
          '--continents',
          '2',
          '--sea-fraction',
          '0.6',
          '--tiles-per-province',
          '35',
        ],
        runInShell: false,
        workingDirectory: _packageRoot,
      );
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(result.stdout, contains('=== Map summary ==='));
    });

    test('prints detailed generation logs (per-pass)', () async {
      final result = await Process.run(
        'dart',
        [
          'run',
          'generate_map',
          '--provinces',
          '4',
          '--continents',
          '2',
        ],
        runInShell: false,
        workingDirectory: _packageRoot,
      );
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(result.stdout, contains('=== Map generation ==='));
      expect(result.stdout, contains('Pass 1'));
      expect(result.stdout, contains('Pass 3'));
    });

    test('--seed-before-assignment uses legacy land assignment', () async {
      final result = await Process.run(
        'dart',
        [
          'run',
          'generate_map',
          '--provinces',
          '4',
          '--continents',
          '2',
          '--seed',
          '1',
          '--seed-before-assignment',
        ],
        runInShell: false,
        workingDirectory: _packageRoot,
      );
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(result.stdout, contains('=== Map generation ==='));
      expect(result.stdout, contains('Pass 2: Continent seeds'));
      expect(result.stdout, isNot(contains('organic')));
    });

    test('--region invalid exits with error', () async {
      final result = await Process.run(
        'dart',
        [
          'run',
          'generate_map',
          '--provinces',
          '2',
          '--continents',
          '2',
          '--region',
          'invalid',
        ],
        runInShell: false,
        workingDirectory: _packageRoot,
      );
      expect(result.exitCode, 1);
      expect(result.stdout, contains('oldWorld or newWorld'));
    });

    test('--tile-map-image outputs topology graph DOT', () async {
      final tmpDir = Directory.systemTemp.createTempSync('generate_map_test_');
      addTearDown(() => tmpDir.deleteSync(recursive: true));
      final mapPath = p.join(tmpDir.path, 'map.png');
      final result = await Process.run(
        'dart',
        [
          'run',
          'generate_map',
          '--provinces',
          '3',
          '--continents',
          '2',
          '--tile-map-image=$mapPath',
          '--seed',
          '99',
        ],
        runInShell: false,
        workingDirectory: _packageRoot,
      );
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(result.stdout, contains('Topology graph (DOT)'));
      expect(File(mapPath).existsSync(), isTrue);
    });
  });
}
