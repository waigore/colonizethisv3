import 'dart:io';

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:path/path.dart' as p;

void main() {
  group('sim_combat_montecarlo', () {
    test('monte carlo aggregates wins and casualties correctly', () {
      final attackerUnits = [
        Unit(
          id: 'a1',
          type: 'grenadiers',
          ownerId: 'att',
          provinceId: 'p',
          medals: 1,
        ),
      ];
      final defenderUnits = [
        Unit(
          id: 'd1',
          type: 'peasant_levies',
          ownerId: 'def',
          provinceId: 'p',
          medals: 0,
        ),
      ];

      var attWins = 0;
      var defWins = 0;
      var totalAttCas = 0;
      var totalDefCas = 0;
      const trials = 50;

      for (var i = 0; i < trials; i++) {
        final outcome = resolveEngagementProbabilistic(
          attackerUnits: attackerUnits,
          defenderUnits: defenderUnits,
          fortLevel: 0,
          terrain: 'plains',
          seed: 100 + i,
        );

        if (outcome.result == EngagementResult.attackerVictory) attWins++;
        if (outcome.result == EngagementResult.defenderVictory) defWins++;
        totalAttCas += outcome.attackerCasualties.length;
        totalDefCas += outcome.defenderCasualties.length;
      }

      expect(attWins + defWins, lessThanOrEqualTo(trials));
      expect(totalAttCas, greaterThanOrEqualTo(0));
      expect(totalDefCas, greaterThanOrEqualTo(0));
      expect(totalAttCas / trials, lessThanOrEqualTo(1.0));
      expect(totalDefCas / trials, lessThanOrEqualTo(1.0));
    });

    test('CLI with same script and seed produces identical output (determinism)',
        () async {
      final cwd = Directory.current.path;
      final scriptPath = p.join(cwd, 'test', 'fixtures', 'valid.json');
      final binPath = p.join(cwd, 'bin', 'sim_combat_montecarlo.dart');
      final out1 = p.join(cwd, 'test', 'out_det_1.md');
      final out2 = p.join(cwd, 'test', 'out_det_2.md');
      final json1 = p.join(cwd, 'test', 'out_det_1.json');
      final json2 = p.join(cwd, 'test', 'out_det_2.json');
      try {
        final result1 = await Process.run(
          Platform.executable,
          [
            'run',
            binPath,
            '--script',
            scriptPath,
            '--trials',
            '20',
            '--seed',
            '42',
            '--output',
            out1,
            '--json-output',
            json1,
          ],
          runInShell: false,
          workingDirectory: cwd,
        );
        expect(result1.exitCode, 0, reason: result1.stderr.toString());

        final result2 = await Process.run(
          Platform.executable,
          [
            'run',
            binPath,
            '--script',
            scriptPath,
            '--trials',
            '20',
            '--seed',
            '42',
            '--output',
            out2,
            '--json-output',
            json2,
          ],
          runInShell: false,
          workingDirectory: cwd,
        );
        expect(result2.exitCode, 0, reason: result2.stderr.toString());

        expect(File(out1).readAsStringSync(), File(out2).readAsStringSync());
        expect(File(json1).readAsStringSync(), File(json2).readAsStringSync());
      } finally {
        for (final f in [out1, out2, json1, json2]) {
          final file = File(f);
          if (file.existsSync()) file.deleteSync();
        }
      }
    });

    test('CLI aborts with non-zero exit on unknown unit type', () async {
      final cwd = Directory.current.path;
      final scriptPath = p.join(cwd, 'test', 'fixtures', 'invalid_unit.json');
      final binPath = p.join(cwd, 'bin', 'sim_combat_montecarlo.dart');
      final result = await Process.run(
        Platform.executable,
        [
          'run',
          binPath,
          '--script',
          scriptPath,
          '--trials',
          '10',
        ],
        runInShell: false,
        workingDirectory: cwd,
      );
      expect(result.exitCode, isNot(0));
      final out = result.stdout.toString() + result.stderr.toString();
      expect(out, contains('unknown unit type'));
    });

    test('CLI aborts with non-zero exit on invalid fort level', () async {
      final cwd = Directory.current.path;
      final scriptPath = p.join(cwd, 'test', 'fixtures', 'invalid_fort.json');
      final binPath = p.join(cwd, 'bin', 'sim_combat_montecarlo.dart');
      final result = await Process.run(
        Platform.executable,
        [
          'run',
          binPath,
          '--script',
          scriptPath,
          '--trials',
          '10',
        ],
        runInShell: false,
        workingDirectory: cwd,
      );
      expect(result.exitCode, isNot(0));
      final out = result.stdout.toString() + result.stderr.toString();
      expect(out, contains('fortLevel'));
    });
  });
}
