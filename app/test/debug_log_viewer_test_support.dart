// Debug log viewer widget-test pumps and row-tint helpers (Refs #4720 Slice G).
// SPEC/program/debug-log-viewer.md.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/debug_log/debug_log_viewer_screen.dart';
import 'package:colonizethis_app/widgets/ct_choice_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

const double debugLogViewerExpectedRowAlpha = 0.08;

CtChoiceChip debugLogViewerChipWithLabel(WidgetTester tester, String label) {
  return tester.widget<CtChoiceChip>(
    find.ancestor(of: find.text(label), matching: find.byType(CtChoiceChip)),
  );
}

/// Returns the resolved row-tint Color for the first line of the matching
/// log entry, or `null` when no tinted container is found. The viewer wraps
/// each line in a `Container` and only the first line of each entry receives
/// a `BoxDecoration` with the level row tint.
Color? debugLogViewerRowTintColorContaining(
  WidgetTester tester,
  String pattern,
) {
  final containerFinder = find.ancestor(
    of: find.textContaining(pattern),
    matching: find.byType(Container),
  );
  for (final element in containerFinder.evaluate()) {
    final container = element.widget as Container;
    final decoration = container.decoration;
    if (decoration is BoxDecoration && decoration.color != null) {
      return decoration.color;
    }
  }
  return null;
}

Future<void> pumpDebugLogLightViewer(
  WidgetTester tester, {
  Widget child = const DebugLogViewerScreen(),
}) async {
  await pumpAppShell(
    tester,
    theme: AppThemes.light,
    settle: true,
    child: child,
  );
}

Future<void> pumpDebugLogEditorialMonocleViewer(WidgetTester tester) async {
  await pumpAppShell(tester, settle: true, child: const DebugLogViewerScreen());
}

void expectDebugLogTintMatches(
  Color? actual,
  Color base, {
  required String reason,
}) {
  expect(actual, isNotNull, reason: reason);
  final expected = base.withValues(alpha: debugLogViewerExpectedRowAlpha);
  expect(actual!.r, closeTo(expected.r, 0.01), reason: '$reason (r)');
  expect(actual.g, closeTo(expected.g, 0.01), reason: '$reason (g)');
  expect(actual.b, closeTo(expected.b, 0.01), reason: '$reason (b)');
  expect(
    actual.a,
    closeTo(debugLogViewerExpectedRowAlpha, 0.005),
    reason: '$reason (a)',
  );
}
