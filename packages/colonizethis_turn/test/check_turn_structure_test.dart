import 'dart:io';

import 'package:colonizethis_test/test.dart';

/// Structural regression guards for the dedup refactor in `colonizethis_turn`
/// (Refs #3565). These lock in two single-source-of-truth helpers so the
/// duplicated literals they replaced cannot silently creep back in:
///
/// * the stockpile commodity delta (`after.quantityOf(k) - before.quantityOf(k)`)
///   must live only in `_stockpileCommodityDeltaMap`
///   (`economy_preview_pipeline.dart`); see issue #3565 item #1.
/// * the turn-seed root (`(game.globalGameSeed ?? 0) ^ (turn * kTurnResolutionSeedMix)`)
///   must live only in `mixTurnSeed` (`turn_resolution_seeds.dart`); see issue
///   #3565 item #4.
///
/// Refs #3701 extends the same single-source pattern to the LCG seed-advance
/// step: the `* kTurnResolutionLcgMultiplier + kTurnResolutionLcgIncrement`
/// advance arithmetic must live only in `advanceTurnSeed`
/// (`turn_resolution_seeds.dart`). The `kTurnResolutionLcgMultiplier` token is
/// the distinctive marker of the advance step (mask-only callers reference only
/// `kTurnResolutionLcgMask`), so guarding it keeps inlined advance copies out.
///
/// Refs #3842: the spy-phase turn multiplier (`7919`) must live only in
/// `kSpyPhaseSeedTurnMultiplier` (`turn_resolution_seeds.dart`).
void main() {
  group('colonizethis_turn structure guards (Refs #3565)', () {
    final libDir = _turnLibDir();

    test('stockpile commodity delta literal lives only in its helper', () {
      final pattern = RegExp(r'quantityOf\([^)]*\)\s*-\s*\w+\.quantityOf\(');
      final offenders = _filesMatching(
        libDir,
        pattern,
        allowed: 'economy_preview_pipeline.dart',
      );
      expect(
        offenders,
        isEmpty,
        reason:
            'after-before stockpile deltas must reuse _stockpileCommodityDeltaMap '
            '(economy_preview_pipeline.dart). Inlined copies found in:\n'
            '${offenders.join('\n')}',
      );
    });

    test('turn-seed root literal lives only in mixTurnSeed', () {
      final pattern = RegExp(r'globalGameSeed\s*\?\?\s*0\)\s*\^');
      final offenders = _filesMatching(
        libDir,
        pattern,
        allowed: 'turn_resolution_seeds.dart',
      );
      expect(
        offenders,
        isEmpty,
        reason:
            'turn-seed roots must reuse mixTurnSeed (turn_resolution_seeds.dart). '
            'Inlined copies found in:\n${offenders.join('\n')}',
      );
    });

    test('LCG seed-advance literal lives only in advanceTurnSeed', () {
      final pattern = RegExp('kTurnResolutionLcgMultiplier');
      final offenders = _filesMatching(
        libDir,
        pattern,
        allowed: 'turn_resolution_seeds.dart',
      );
      expect(
        offenders,
        isEmpty,
        reason:
            'LCG seed-advance steps must reuse advanceTurnSeed '
            '(turn_resolution_seeds.dart). Inlined copies found in:\n'
            '${offenders.join('\n')}',
      );
    });

    test('spy-phase seed turn multiplier lives only in turn_resolution_seeds',
        () {
      final pattern = RegExp(r'\b7919\b');
      final offenders = _filesMatching(
        libDir,
        pattern,
        allowed: 'turn_resolution_seeds.dart',
      );
      expect(
        offenders,
        isEmpty,
        reason:
            'spy-phase seed mixing must reuse kSpyPhaseSeedTurnMultiplier '
            '(turn_resolution_seeds.dart). Inlined copies found in:\n'
            '${offenders.join('\n')}',
      );
    });

    test('deliverGameEvent dispatch lives only in TurnEventSink', () {
      // Theme B (Refs #3701): the game-event transport is centralized in
      // TurnEventSink.emit, so emitters and phase handlers depend on the sink
      // instead of calling deliverGameEvent directly. Any new direct call is a
      // regression that re-couples a call site to the raw transport.
      final pattern = RegExp(r'deliverGameEvent\s*\(');
      final offenders = _filesMatching(
        libDir,
        pattern,
        allowed: 'turn_event_sink.dart',
      );
      expect(
        offenders,
        isEmpty,
        reason:
            'deliverGameEvent dispatch must go through TurnEventSink.emit '
            '(turn_event_sink.dart). Direct calls found in:\n'
            '${offenders.join('\n')}',
      );
    });

    test('guard patterns still match their canonical helpers', () {
      // Sanity: the guards are meaningful only if the canonical sources still
      // contain the patterns. This fails loudly if a helper is renamed/moved.
      final delta = File(
        '${libDir.path}/src/turn/economy_preview_pipeline.dart',
      ).readAsStringSync();
      final seeds = File(
        '${libDir.path}/src/turn/turn_resolution_seeds.dart',
      ).readAsStringSync();
      expect(
        RegExp(r'quantityOf\([^)]*\)\s*-\s*\w+\.quantityOf\(').hasMatch(delta),
        isTrue,
      );
      expect(
        RegExp(r'globalGameSeed\s*\?\?\s*0\)\s*\^').hasMatch(seeds),
        isTrue,
      );
      expect(
        seeds.contains('int advanceTurnSeed('),
        isTrue,
        reason: 'advanceTurnSeed must remain defined in turn_resolution_seeds.dart',
      );
      expect(
        seeds.contains('kSpyPhaseSeedTurnMultiplier'),
        isTrue,
        reason:
            'kSpyPhaseSeedTurnMultiplier must remain defined in '
            'turn_resolution_seeds.dart',
      );
      expect(
        RegExp(
          r'kTurnResolutionLcgMultiplier\s*\+\s*kTurnResolutionLcgIncrement',
        ).hasMatch(seeds),
        isTrue,
      );
      final sink = File(
        '${libDir.path}/src/turn/turn_event_sink.dart',
      ).readAsStringSync();
      expect(
        RegExp(r'deliverGameEvent\s*\(').hasMatch(sink),
        isTrue,
        reason:
            'TurnEventSink.emit must remain the single deliverGameEvent caller '
            'in turn_event_sink.dart',
      );
    });
  });
}

/// Locates the `lib` directory of the `colonizethis_turn` package, walking up
/// from the current working directory so the test works whether run from the
/// package root (`dart test`) or a melos-managed parent.
Directory _turnLibDir() {
  var dir = Directory.current;
  for (var i = 0; i < 6; i++) {
    final direct = Directory('${dir.path}/lib/src/turn');
    if (direct.existsSync()) return Directory('${dir.path}/lib');
    final nested = Directory(
      '${dir.path}/packages/colonizethis_turn/lib/src/turn',
    );
    if (nested.existsSync()) {
      return Directory('${dir.path}/packages/colonizethis_turn/lib');
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  fail('Could not locate colonizethis_turn/lib from ${Directory.current.path}');
}

List<String> _filesMatching(
  Directory libDir,
  RegExp pattern, {
  required String allowed,
}) {
  final offenders = <String>[];
  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith(allowed)) continue;
    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      if (pattern.hasMatch(lines[i])) {
        offenders.add('${entity.path}:${i + 1}');
      }
    }
  }
  return offenders;
}
