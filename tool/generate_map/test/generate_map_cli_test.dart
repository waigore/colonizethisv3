import 'dart:io';
import 'package:colonizethis_test/test.dart';

import 'package:path/path.dart' as p;

// Import the bin file directly to access the parseMapArguments function.
// ignore: avoid_relative_lib_imports
import '../bin/generate_map.dart' as generate_map;

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

    test('--continents 1 exits with error and message on stderr', () async {
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
      expect(result.stderr, contains('2–4'));
    });

    test('--continents 5 exits with error and message on stderr', () async {
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
      expect(result.stderr, contains('2–4'));
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

    test('happy path produces concise summary and topology sections on stdout', () async {
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
      expect(result.stdout, contains('Generating map: 4 provinces, 2 continents'));
      expect(result.stdout, contains('=== Topology graph ==='));
      expect(result.stdout, contains('=== Map summary ==='));
    });

    test('--seed-before-assignment runs successfully and produces summary', () async {
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
      expect(result.stdout, contains('Generating map: 4 provinces, 2 continents'));
      expect(result.stdout, contains('=== Topology graph ==='));
      expect(result.stdout, contains('=== Map summary ==='));
    });

    test('--region invalid exits with error and message on stderr', () async {
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
      expect(result.stderr, contains('oldWorld or newWorld'));
    });

    test('--tile-map-image outputs PNG and topology graph DOT', () async {
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
      expect(result.stdout, contains('=== Map summary ==='));
      expect(File(mapPath).existsSync(), isTrue);
    });

    test('--provinces 0 exits with error and message on stderr', () async {
      final result = await Process.run(
        'dart',
        [
          'run',
          'generate_map',
          '--provinces',
          '0',
          '--continents',
          '2',
        ],
        runInShell: false,
        workingDirectory: _packageRoot,
      );
      expect(result.exitCode, 1);
      expect(result.stderr, contains('provinces'));
    });

    test('--sea-fraction out of range exits with error on stderr', () async {
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
          '1.0',
        ],
        runInShell: false,
        workingDirectory: _packageRoot,
      );
      expect(result.exitCode, 1);
      expect(result.stderr, contains('sea-fraction'));
    });

    test('--tile-size 0 with tile-map-image exits with error on stderr', () async {
      final tmpDir = Directory.systemTemp.createTempSync('generate_map_test_');
      addTearDown(() => tmpDir.deleteSync(recursive: true));
      final mapPath = p.join(tmpDir.path, 'out.png');
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
          '--tile-size',
          '0',
        ],
        runInShell: false,
        workingDirectory: _packageRoot,
      );
      expect(result.exitCode, 1);
      expect(result.stderr, contains('tile-size'));
    });

    test('--world-state with missing file exits with error on stderr', () async {
      final result = await Process.run(
        'dart',
        [
          'run',
          'generate_map',
          '--provinces',
          '4',
          '--continents',
          '2',
          '--world-state',
          '/nonexistent/world_state.json',
        ],
        runInShell: false,
        workingDirectory: _packageRoot,
      );
      expect(result.exitCode, 1);
      expect(result.stderr, contains('not found'));
    });
  });

  group('parseMapArguments', () {
    test('parses default values when no args provided', () {
      final args = generate_map.parseMapArguments([]);
      expect(args.numProvinces, 60);
      expect(args.numContinents, 3);
      expect(args.regionId, 'oldWorld');
      expect(args.interactive, false);
      expect(args.withTileMapImage, false);
    });

    test('parses explicit --provinces and --continents', () {
      final args = generate_map.parseMapArguments(['--provinces', '20', '--continents', '2']);
      expect(args.numProvinces, 20);
      expect(args.numContinents, 2);
    });

    test('parses --region newWorld', () {
      final args = generate_map.parseMapArguments(['--region', 'newWorld']);
      expect(args.regionId, 'newWorld');
    });

    test('parses --interactive flag', () {
      final args = generate_map.parseMapArguments(['--interactive']);
      expect(args.interactive, true);
    });

    test('parses --tile-map-image with path', () {
      final args = generate_map.parseMapArguments(['--tile-map-image=/tmp/map.png']);
      expect(args.withTileMapImage, true);
      expect(args.tileMapImagePath, '/tmp/map.png');
    });

    test('parses --seed', () {
      final args = generate_map.parseMapArguments(['--seed', '12345']);
      expect(args.seedUsed, 12345);
    });
  });
}
