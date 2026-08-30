// Shared WidgetTester hosts and debugPrint/counter helpers for the
// `e2e_dismiss_*` mirror-test family (Slice C / AC5–AC6 of #4075).
//
// Seven dismiss suites previously re-declared `_captureDebugPrints`,
// counter-line matchers, MaterialApp wrappers, and StatefulWidget hosts for
// AlertDialog / SnackBar / CtDialogShell fixtures. This harness consolidates
// that scaffolding so each suite keeps only its behavioural axes (priority,
// hit-testable filter, perf counters, pop-route escalation).
//
// Do not change production helper semantics from here — test scaffolding only.
//
// Refs #4075.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dismiss_widget_tester_hosts.dart';
export 'dismiss_widget_tester_hosts.dart';

/// Captures every `debugPrint` line emitted while [body] runs and restores
/// the original printer afterwards.
///
/// When [expectThrows] is `true`, a [TestFailure] from [body] is swallowed
/// so callers can assert on captured lines from fail-path helpers; any other
/// exception still propagates. When [expectThrows] is `false` (default),
/// [TestFailure] and other errors propagate after restoring `debugPrint`.
/// If [expectThrows] is `true` and [body] returns normally, throws a
/// [StateError].
Future<List<String>> captureE2eDebugPrints(
  Future<void> Function() body, {
  bool expectThrows = false,
}) async {
  final captured = <String>[];
  final original = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    captured.add(message ?? '');
  };
  try {
    await body();
    if (expectThrows) {
      throw StateError(
        'Expected body to throw but it returned normally; captured lines: '
        '$captured',
      );
    }
  } on TestFailure {
    if (!expectThrows) {
      rethrow;
    }
  } finally {
    debugPrint = original;
  }
  return captured;
}

/// Exact-match pin for an [E2ePerfLog.bumpCounter] line:
/// `E2E_COUNTER|test=$test|name=$name|value=$expectedValue`.
bool hasE2eCounterLine(
  List<String> lines, {
  required String test,
  required String name,
  required int expectedValue,
}) {
  final needle = 'E2E_COUNTER|test=$test|name=$name|value=$expectedValue';
  return lines.any((line) => line == needle);
}

/// Prefix pin that any counter value was emitted for [test]/[name].
bool hasAnyE2eCounterLine(
  List<String> lines, {
  required String test,
  required String name,
}) {
  final prefix = 'E2E_COUNTER|test=$test|name=$name|';
  return lines.any((line) => line.startsWith(prefix));
}

/// `MaterialApp(home: home)` — for hosts that already supply a [Scaffold].
Widget wrapDismissMaterial(Widget home) => MaterialApp(home: home);

/// `MaterialApp` → [Scaffold] → centered [body].
Widget wrapDismissCentered(Widget body) => MaterialApp(
  home: Scaffold(body: Center(child: body)),
);

Future<void> pumpDismissMaterial(WidgetTester tester, Widget home) async {
  await tester.pumpWidget(wrapDismissMaterial(home));
}

Future<void> pumpDismissCentered(WidgetTester tester, Widget body) async {
  await tester.pumpWidget(wrapDismissCentered(body));
}

/// One idle frame plus 250 ms — settles post-frame `showDialog` / SnackBar
/// hosts before the helper under test runs.
Future<void> pumpDismissOverlaySettle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

/// Short post-tap settle (50 ms) used after dismiss helpers return.
Future<void> pumpDismissPostTapSettle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 50));
}

/// Post-frame [AlertDialog] host with overlay settle — common dismiss-suite pump.
Future<void> pumpDismissPostFrameAlertDialog(
  WidgetTester tester,
  WidgetBuilder dialogBuilder, {
  bool barrierDismissible = false,
}) async {
  await pumpDismissMaterial(
    tester,
    DismissPostFrameDialogHost(
      dialogBuilder: dialogBuilder,
      barrierDismissible: barrierDismissible,
    ),
  );
  await pumpDismissOverlaySettle(tester);
}
