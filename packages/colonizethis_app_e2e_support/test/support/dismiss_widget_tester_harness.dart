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

import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  final needle =
      'E2E_COUNTER|test=$test|name=$name|value=$expectedValue';
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
Widget wrapDismissCentered(Widget body) =>
    MaterialApp(home: Scaffold(body: Center(child: body)));

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

/// Surfaces a route via `showDialog` once after the first frame so test
/// bodies can assert against a steady dialog without driving `showDialog`
/// from a stateless [Widget.build].
///
/// Used for [AlertDialog] and route-mounted [CtDialogShell] fixtures.
class DismissPostFrameDialogHost extends StatefulWidget {
  const DismissPostFrameDialogHost({
    super.key,
    required this.dialogBuilder,
    this.barrierDismissible = false,
  });

  final WidgetBuilder dialogBuilder;
  final bool barrierDismissible;

  @override
  State<DismissPostFrameDialogHost> createState() =>
      _DismissPostFrameDialogHostState();
}

class _DismissPostFrameDialogHostState extends State<DismissPostFrameDialogHost> {
  bool _shown = false;

  void _show(BuildContext context) {
    if (_shown) return;
    _shown = true;
    showDialog<void>(
      context: context,
      barrierDismissible: widget.barrierDismissible,
      builder: widget.dialogBuilder,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (innerCtx) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _show(innerCtx));
          return const SizedBox.expand();
        },
      ),
    );
  }
}

/// Surfaces a [SnackBar] once after the first frame via [ScaffoldMessenger].
class DismissSnackBarHost extends StatefulWidget {
  const DismissSnackBarHost({super.key, required this.snackBar});

  final SnackBar snackBar;

  @override
  State<DismissSnackBarHost> createState() => _DismissSnackBarHostState();
}

class _DismissSnackBarHostState extends State<DismissSnackBarHost> {
  bool _shown = false;

  void _show(BuildContext context) {
    if (_shown) return;
    _shown = true;
    ScaffoldMessenger.of(context).showSnackBar(widget.snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (innerCtx) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _show(innerCtx));
          return const SizedBox.expand();
        },
      ),
    );
  }
}

/// Hosts a [CtDialogShell] whose contents receive a [close] callback that
/// unmounts the shell (state flip to [SizedBox.shrink]).
class DismissCtDialogShellHost extends StatefulWidget {
  const DismissCtDialogShellHost({super.key, required this.builder});

  final Widget Function(BuildContext context, VoidCallback close) builder;

  @override
  State<DismissCtDialogShellHost> createState() =>
      _DismissCtDialogShellHostState();
}

class _DismissCtDialogShellHostState extends State<DismissCtDialogShellHost> {
  bool open = true;

  void _close() {
    setState(() => open = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!open) {
      return const SizedBox.shrink();
    }
    return CtDialogShell(child: widget.builder(context, _close));
  }
}

/// Stacks an opaque [AbsorbPointer] fill over [child] so the child remains
/// mounted but non-hit-testable — the hit-testable-filter fixture pattern.
Widget absorbPointerCover({required Widget child}) {
  return Stack(
    children: [
      child,
      const Positioned.fill(
        child: AbsorbPointer(
          child: ColoredBox(color: Color(0xFFFF0000)),
        ),
      ),
    ],
  );
}


/// AlertDialog whose first labelled action is covered (non-hit-testable) and
/// whose second labelled action remains hit-testable.
Widget coveredFirstActionAlertDialog({
  required String firstLabel,
  required String secondLabel,
}) {
  return Builder(
    builder: (context) {
      return AlertDialog(
        title: const Text('covered-first-dialog'),
        actions: [
          SizedBox(
            width: 120,
            height: 48,
            child: absorbPointerCover(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(firstLabel),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(secondLabel),
          ),
        ],
      );
    },
  );
}
