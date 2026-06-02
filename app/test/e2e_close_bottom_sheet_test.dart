// Asserts the pop-once-then-poll contract of `e2eCloseBottomSheet` (Refs
// GitHub #2336 pump-reduction slice). The previous implementation called
// `tester.binding.handlePopRoute` on every poll iteration, racing the
// dismiss animation; the rewritten helper pops once and polls with
// `e2ePumpUntilConditionOrIdle` so the loop exits the moment the bottom
// sheet leaves the widget tree.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

class _BottomSheetHost extends StatefulWidget {
  const _BottomSheetHost();

  @override
  State<_BottomSheetHost> createState() => _BottomSheetHostState();
}

class _BottomSheetHostState extends State<_BottomSheetHost> {
  bool _opened = false;

  void _open(BuildContext context) {
    if (_opened) return;
    _opened = true;
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => const SizedBox(
        height: 200,
        child: Center(child: Text('panel-content')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (innerCtx) {
          // Open after first frame; tests pump before asserting.
          WidgetsBinding.instance.addPostFrameCallback((_) => _open(innerCtx));
          return const SizedBox.expand();
        },
      ),
    );
  }
}

void main() {
  suppressLogsForTests();

  testWidgets('e2eCloseBottomSheet returns immediately when no sheet exists', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final sw = Stopwatch()..start();
    await e2eCloseBottomSheet(tester);
    expect(
      sw.elapsed < const Duration(milliseconds: 100),
      isTrue,
      reason:
          'No-sheet calls must short-circuit before pumping any frame so the '
          'helper does not amplify caller cost when nothing is open.',
    );
  });

  testWidgets('e2eCloseBottomSheet dismisses a real BottomSheet within budget', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _BottomSheetHost()));
    // The post-frame callback schedules the sheet; pump a couple of frames so
    // the modal bottom sheet route is fully mounted before the helper runs.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(BottomSheet), findsOneWidget);

    final sw = Stopwatch()..start();
    await e2eCloseBottomSheet(tester);
    expect(find.byType(BottomSheet), findsNothing);
    expect(
      sw.elapsed < const Duration(seconds: 2),
      isTrue,
      reason:
          'Pop-once-then-poll must finish well inside the 5s default budget '
          'on a clean dismiss path (Refs GitHub #2336).',
    );
  });

  testWidgets('e2eCloseBottomSheet respects a tight overallTimeout window', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _BottomSheetHost()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(BottomSheet), findsOneWidget);

    // 1s is enough for the dismiss animation but tests that the helper still
    // works when callers pass a tighter window than the 5s default.
    await e2eCloseBottomSheet(
      tester,
      overallTimeout: const Duration(seconds: 1),
    );
    expect(find.byType(BottomSheet), findsNothing);
  });
}
