import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_test/test.dart';

import 'package:ga_runner/observer/observer_runner.dart';

/// Tests for the observer trace/snapshot resolution contract.
/// SPEC/program/ga-runner.md § Observer contract. Refs #3439.
void main() {
  group('findLatestObserverGameTraceDir', () {
    test('returns null when observer-traces directory is absent', () async {
      final root = await Directory.systemTemp.createTemp('ga_obs_noroot_');
      try {
        expect(findLatestObserverGameTraceDir(root.path), isNull);
      } finally {
        await root.delete(recursive: true);
      }
    });

    test('returns null when observer-traces directory has no game dirs',
        () async {
      final root = await Directory.systemTemp.createTemp('ga_obs_empty_');
      try {
        await Directory('${root.path}/observer-traces').create(recursive: true);
        expect(findLatestObserverGameTraceDir(root.path), isNull);
      } finally {
        await root.delete(recursive: true);
      }
    });

    test('returns the most recently modified game trace directory', () async {
      final root = await Directory.systemTemp.createTemp('ga_obs_latest_');
      try {
        final older = Directory('${root.path}/observer-traces/game-old')
          ..createSync(recursive: true);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final newer = Directory('${root.path}/observer-traces/game-new')
          ..createSync(recursive: true);
        // Bump the newer directory's mtime deterministically after the delay.
        File('${newer.path}/marker.txt').writeAsStringSync('x');

        final resolved = findLatestObserverGameTraceDir(root.path);
        expect(resolved, newer.path);
        expect(resolved, isNot(older.path));
      } finally {
        await root.delete(recursive: true);
      }
    });
  });

  group('loadFinalObserverArtifacts', () {
    Future<Directory> traceDir(String prefix) =>
        Directory.systemTemp.createTemp(prefix);

    void writeSummary(String dir, Object content) {
      File('$dir/run-summary.json').writeAsStringSync(
        content is String ? content : jsonEncode(content),
      );
    }

    test('returns null when run-summary.json is missing', () async {
      final dir = await traceDir('ga_art_nosummary_');
      try {
        File('${dir.path}/turn-000001.snapshot.json')
            .writeAsStringSync(jsonEncode(<String, dynamic>{'turn': 1}));
        expect(loadFinalObserverArtifacts(dir.path), isNull);
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('returns null when run-summary.json is malformed JSON', () async {
      final dir = await traceDir('ga_art_badsummary_');
      try {
        writeSummary(dir.path, '{not valid json');
        File('${dir.path}/turn-000001.snapshot.json')
            .writeAsStringSync(jsonEncode(<String, dynamic>{'turn': 1}));
        expect(loadFinalObserverArtifacts(dir.path), isNull);
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('returns null when no snapshot file is present', () async {
      final dir = await traceDir('ga_art_nosnap_');
      try {
        writeSummary(dir.path, <String, dynamic>{'termination_reason': 'cap'});
        expect(loadFinalObserverArtifacts(dir.path), isNull);
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('returns null when the snapshot file is malformed JSON', () async {
      final dir = await traceDir('ga_art_badsnap_');
      try {
        writeSummary(dir.path, <String, dynamic>{'termination_reason': 'cap'});
        File('${dir.path}/turn-000001.snapshot.json')
            .writeAsStringSync('{broken');
        expect(loadFinalObserverArtifacts(dir.path), isNull);
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('returns the highest-turn snapshot with the run summary', () async {
      final dir = await traceDir('ga_art_ok_');
      try {
        writeSummary(dir.path, <String, dynamic>{
          'declared_winner_player_id': 'gp1',
          'termination_reason': 'military_victory',
        });
        // Unpadded turn numbers prove numeric (not lexicographic) selection:
        // lexicographic max is "turn-2", numeric max is "turn-10".
        File('${dir.path}/turn-2.snapshot.json')
            .writeAsStringSync(jsonEncode(<String, dynamic>{'turn': 2}));
        File('${dir.path}/turn-10.snapshot.json')
            .writeAsStringSync(jsonEncode(<String, dynamic>{'turn': 10}));
        // Non-matching files must be ignored.
        File('${dir.path}/notes.txt').writeAsStringSync('ignore me');

        final artifacts = loadFinalObserverArtifacts(dir.path);
        expect(artifacts, isNotNull);
        expect(artifacts!.snapshot['turn'], 10);
        expect(artifacts.runSummary['declared_winner_player_id'], 'gp1');
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}
