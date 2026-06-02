/// Pins the AC2 "no surviving file-scope private constants" contract for
/// the fleet-reach E2E scenario library
/// (`app/integration_test/new_game_fleet_reaches_new_world_e2e_test.dart`).
///
/// The library previously carried two `part` files
/// (`new_game_fleet_reaches_new_world_e2e_helpers.dart` and
/// `…_helpers_part2.dart`) that, after the lift cadence #2720–#2758, held
/// only documentation breadcrumbs and zero live code. Those `part` files
/// have been retired; this pin both enforces their non-reappearance and
/// re-asserts that the remaining single library file carries no file-scope
/// `_k*` private constants (Refs GitHub #2336 AC1 / AC2 / Bottleneck 6).
///
/// Before that slice, the library carried three private file-scope
/// constants in `new_game_fleet_reaches_new_world_e2e_helpers.dart` that
/// duplicated public constants already exported through the AC1 barrel
/// (`app/integration_test/e2e_helpers.dart`):
///
/// | Retired private (legacy literal)                | Public replacement                  | Source                                  |
/// |-------------------------------------------------|-------------------------------------|-----------------------------------------|
/// | `_kMaxNextTurnTapsForNwFleetReach` (`35`)       | `kE2eDefaultFleetReachLoopMaxTurns` | `e2e_test_shared_fleet_reach_loop.dart` |
/// | `_kMaxUiResponseWait` (`Duration(seconds: 5)`)  | `kE2eDefaultNavalMoveSegmentUiWait` | `e2e_test_shared_panels.dart`           |
/// | `_kFleetE2eMaxWallClock` (`kE2eMaxWallClock`)   | `kE2eMaxWallClock`                  | `e2e_test_shared.dart`                  |
///
/// AC2 requires that the four E2E test files contain no duplicated private
/// helper or constant whose semantics are already supplied by the shared
/// library. Per-constant value pins already exist
/// (`e2e_fleet_reach_turn_loop_test.dart`, `e2e_try_naval_move_segment_test.dart`,
/// `e2e_make_wall_clock_guard_test.dart`), but they each cover one constant
/// in isolation. This file is the single AC2 source-of-truth pin that:
///
/// 1. Re-asserts the byte-identical legacy literals on the public
///    replacements so a coordinated rename of one of the three constants
///    cannot silently drift any single leg of the migration off the
///    pre-lift value.
/// 2. Reads the integration test library source on disk and asserts that
///    none of the three retired private symbols (or any other `^const
///    _k...` file-scope private constant) reappears in the library — the
///    structural guard that the migration was completed in source, not
///    merely papered over by a value-equal proxy.
///
/// A regression that re-introduced `_kMaxNextTurnTapsForNwFleetReach =
/// 35` (for example) would compile and pass every existing per-constant
/// pin, but would also re-create the AC2-violating duplication the
/// `e2e_test_shared_fleet_reach_loop.dart` lift was meant to retire. This
/// pin makes that regression fail in `flutter test test/` before it can
/// land on `dev`.
///
/// The integration suite itself cannot enforce this today (the
/// `app_e2e_linux` lane is a no-op per
/// `SPEC/program/e2e-integration-tests.md` § CI), so this widget-test
/// layer carries the AC2 source-of-truth pin.
///
/// Refs GitHub #2336 AC1 / AC2 / Bottleneck 6.
library;

import 'dart:io';

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_helpers.dart';

const String _integrationTestRelativePath =
    'integration_test/new_game_fleet_reaches_new_world_e2e_test.dart';

/// Retired `part` files whose private helpers and constants have been lifted
/// into the AC1 barrel (`app/integration_test/e2e_helpers.dart`) and the
/// shared `e2e_test_shared*.dart` modules. Each entry is asserted **not** to
/// exist on disk so a regression that re-introduces a `part` file (and the
/// AC2-violating private symbols it would tend to host) fails before it can
/// land on `dev`.
const List<String> _retiredHelpersPartFileRelativePaths = <String>[
  'integration_test/new_game_fleet_reaches_new_world_e2e_helpers.dart',
  'integration_test/new_game_fleet_reaches_new_world_e2e_helpers_part2.dart',
];

const List<String> _retiredPrivateConstantNames = <String>[
  '_kMaxNextTurnTapsForNwFleetReach',
  '_kMaxUiResponseWait',
  '_kFleetE2eMaxWallClock',
];

/// Anchored regex that matches any file-scope `const _kXxx = ...;` line in
/// Dart source — i.e. the AC2-violating shape this pin retired. The
/// `multiLine: true` flag lets `^` match the start of any line in the
/// file, not only the start of the whole string.
final RegExp _fileScopePrivateConstantPattern = RegExp(
  r'^const\s+(?:final\s+)?[A-Za-z_<>?,\s\.]+?\s+_k[A-Za-z0-9_]+\s*=',
  multiLine: true,
);

List<File> _integrationTestSourceCandidates(String relativePath) {
  final repoRoot = Directory.current.path;
  // app/test/ is the typical working directory under `flutter test`; the
  // fallback `..` path traversal keeps the test runnable from either the
  // repo root or the `app/` directory without requiring a custom Flutter
  // test runner invocation.
  return <File>[
    File('$repoRoot/$relativePath'),
    File('$repoRoot/app/$relativePath'),
    File('$repoRoot/../$relativePath'),
  ];
}

String _readIntegrationTestSource(String relativePath) {
  for (final file in _integrationTestSourceCandidates(relativePath)) {
    if (file.existsSync()) {
      return file.readAsStringSync();
    }
  }
  fail(
    'Could not locate integration test source at any of: '
    '${_integrationTestSourceCandidates(relativePath).map((f) => f.path).join(', ')}. '
    'AC2 source-of-truth pin must read the integration_test library to '
    'guard against re-introduction of file-scope private constants.',
  );
}

void main() {
  suppressLogsForTests();
  group('AC2 — legacy private fleet-reach constants now public', () {
    test('kE2eDefaultFleetReachLoopMaxTurns preserves the legacy '
        '_kMaxNextTurnTapsForNwFleetReach (35) value', () {
      expect(
        kE2eDefaultFleetReachLoopMaxTurns,
        35,
        reason:
            'Migration target [kE2eDefaultFleetReachLoopMaxTurns] must keep '
            'the byte-identical literal of the retired private '
            '`_kMaxNextTurnTapsForNwFleetReach` (35) so the fleet-reach '
            'scenarios exercise the same Bottleneck 4 ceiling they used '
            'pre-lift (Refs GitHub #2336 AC1 / AC2).',
      );
    });

    test('kE2eDefaultNavalMoveSegmentUiWait preserves the legacy '
        '_kMaxUiResponseWait (Duration(seconds: 5)) value', () {
      expect(
        kE2eDefaultNavalMoveSegmentUiWait,
        const Duration(seconds: 5),
        reason:
            'Migration target [kE2eDefaultNavalMoveSegmentUiWait] must keep '
            'the byte-identical literal of the retired private '
            '`_kMaxUiResponseWait` (5 s) so every fleet-reach UI-response '
            'wait (move dialog, naval panel open, post-loop snapshot '
            'reach) fails fast at the same Bottleneck 4 boundary it used '
            'pre-lift (Refs GitHub #2336 AC1 / AC2).',
      );
    });

    test('kE2eMaxWallClock preserves the legacy _kFleetE2eMaxWallClock '
        '(Duration(minutes: 5)) alias', () {
      expect(
        kE2eMaxWallClock,
        const Duration(minutes: 5),
        reason:
            'Migration target [kE2eMaxWallClock] must keep the byte-'
            'identical 5-minute wall-clock cap the retired private '
            '`_kFleetE2eMaxWallClock` aliased so the PR runtime rule in '
            '`SPEC/program/e2e-integration-tests.md` § Determinism remains '
            'enforced across all three E2E scenarios (Refs GitHub #2336 '
            'AC10).',
      );
    });
  });

  group('AC2 — fleet-reach E2E library carries no file-scope private '
      'constants', () {
    test('integration test library source contains no `_k*` private constants '
        '(none of the three retired names, and no other file-scope `^const '
        '_k...` declarations)', () {
      final sources = <String, String>{
        _integrationTestRelativePath: _readIntegrationTestSource(
          _integrationTestRelativePath,
        ),
      };

      for (final entry in sources.entries) {
        final source = entry.value;
        // Strip Dart line and block comments so doc-comment provenance
        // references (e.g. "lifted from `_kMaxNextTurnTapsForNwFleetReach`")
        // do not falsely trigger the structural guard. Only live code
        // declarations should match.
        final code = source
            .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
            .replaceAll(RegExp(r'//[^\n]*'), '');

        for (final retired in _retiredPrivateConstantNames) {
          final declPattern = RegExp(
            '^[^\\n]*\\b$retired\\s*=',
            multiLine: true,
          );
          expect(
            declPattern.hasMatch(code),
            isFalse,
            reason:
                '${entry.key} must not re-introduce the retired private '
                'constant `$retired` (AC2 § no surviving file-scope '
                'duplicates of shared-library values). Use the public '
                'replacement from the AC1 barrel '
                '(`e2e_helpers.dart`) instead.',
          );
        }

        final structuralMatches = _fileScopePrivateConstantPattern
            .allMatches(code)
            .map((m) => m.group(0))
            .toList(growable: false);
        expect(
          structuralMatches,
          isEmpty,
          reason:
              '${entry.key} must not declare any file-scope `_k*` private '
              'constant (AC2 source-of-truth pin). If a new shared value '
              'is needed, expose it as a public `kE2eDefault*` constant on '
              'the shared library (`e2e_test_shared*.dart`) and consume '
              'it through the AC1 barrel (`e2e_helpers.dart`). Matches: '
              '$structuralMatches.',
        );
      }
    });
  });

  group('AC2 — retired `part` helper files stay retired', () {
    test('historical `part` files for the fleet-reach E2E scenario library do '
        'not reappear on disk (`new_game_fleet_reaches_new_world_e2e_helpers'
        '.dart` and `…_helpers_part2.dart`)', () {
      for (final retired in _retiredHelpersPartFileRelativePaths) {
        final reappearedPaths = _integrationTestSourceCandidates(retired)
            .where((file) => file.existsSync())
            .map((file) => file.path)
            .toList(growable: false);
        expect(
          reappearedPaths,
          isEmpty,
          reason:
              'Retired `part` helper file `$retired` reappeared at: '
              '$reappearedPaths. Both legacy `part` files held only '
              'documentation breadcrumbs after the AC1/AC2 lift cadence '
              '(#2720–#2758) finished evacuating every private helper into '
              'the shared `e2e_helpers.dart` barrel. Re-introducing a `part` '
              'file is the structural shape that historically hosted '
              'AC2-violating file-scope `_k*` constants and private '
              'orchestration helpers, so this pin keeps the surface area '
              'collapsed. If a new shared helper is needed, add it under '
              '`app/integration_test/e2e_test_shared*.dart` and re-export it '
              'through the AC1 barrel instead of resurrecting a per-scenario '
              '`part` file (Refs GitHub #2336 AC1 / AC2 / Bottleneck 6).',
        );
      }
    });
  });
}
