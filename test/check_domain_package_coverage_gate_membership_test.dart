import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Guards the split-domain-package coverage-gate membership wired into
/// `tool/run_package_tests.sh`
/// (SPEC/program/logic-package-split-phase0.md § Domain-package coverage gates,
/// Refs #3290).
///
/// PR #3386 lifted `colonizethis_world` standalone coverage to >=90% and enabled
/// its 90% gate (removing the historical post-extraction deferral). These checks
/// pin that contract so a future edit cannot silently drop a split domain
/// package from the 90% gate or re-introduce the `colonizethis_world` deferral
/// without a SPEC + test update.
void main() {
  final script = File(
    p.join(Directory.current.path, 'tool', 'run_package_tests.sh'),
  ).readAsStringSync();

  group('run_package_tests.sh coverage-gate membership', () {
    test('90% gate covers all eight split domain packages + logic/map/ai', () {
      final gated = _coverageGatePackagesForThreshold(script, 90);
      const expected = {
        'colonizethis_logic',
        'colonizethis_map',
        'colonizethis_ai',
        'colonizethis_ai_contracts',
        'colonizethis_world',
        'colonizethis_combat',
        'colonizethis_economy',
        'colonizethis_diplomacy',
        'colonizethis_setup',
        'colonizethis_orders',
        'colonizethis_turn',
      };
      expect(
        gated,
        containsAll(expected),
        reason: 'Missing from the 90% gate: ${expected.difference(gated)}',
      );
    });

    test('colonizethis_world is wired into the 90% gate (no deferral)', () {
      expect(_coverageGatePackagesForThreshold(script, 90),
          contains('colonizethis_world'));
    });

    test('colonizethis_data is gated at 80%, not 90%', () {
      expect(_coverageGatePackagesForThreshold(script, 80),
          contains('colonizethis_data'));
      expect(_coverageGatePackagesForThreshold(script, 90),
          isNot(contains('colonizethis_data')));
    });
  });
}

/// Extracts the `for pkg in <list>; do` package set whose enclosing block
/// invokes `check_coverage_threshold.sh <threshold>`.
///
/// `run_package_tests.sh` builds each coverage gate as a `for pkg in ...; do`
/// loop that appends matched packages into `gate_pkgs`, then passes that array
/// to `tool/check_coverage_threshold.sh <threshold>`. This walks from each
/// `for pkg in` line forward (until the next such line) to find the threshold
/// invocation that consumes its list.
Set<String> _coverageGatePackagesForThreshold(String script, int threshold) {
  final lines = script.split('\n');
  final forLine = RegExp(r'^\s*for pkg in (.+); do\s*$');
  final invocation =
      RegExp('check_coverage_threshold\\.sh"?\\s+$threshold(?:\\b|\\s)');
  for (var i = 0; i < lines.length; i++) {
    final match = forLine.firstMatch(lines[i]);
    if (match == null) continue;
    for (var j = i + 1; j < lines.length; j++) {
      if (forLine.hasMatch(lines[j])) break;
      if (invocation.hasMatch(lines[j])) {
        return match.group(1)!.trim().split(RegExp(r'\s+')).toSet();
      }
    }
  }
  return <String>{};
}
