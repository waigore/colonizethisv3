/// Widget-test coverage for `e2eClosePanelOpenerSheetAndAwaitOpener`, the
/// shared post-sheet-close cleanup recipe used by `e2eOpenCivilianPanel`
/// and `e2eOpenNavalPanel` whenever a conflicting [BottomSheet] occupies
/// the screen at the start of an outer panel-opener loop iteration.
///
/// The helper is the follow-up slice to PR #2782 that unified the
/// **post-sheet-close** cleanup body the civilian and naval openers each
/// inlined identically before this lift (`close sheet → poll until sheet
/// cleared → poll until rail/marker hit-testable`, with only the
/// `pump_until_<civilian|naval>_opener_after_sheet_close` phase-label
/// suffix differing between them).
///
/// Because `integration_test/` is not part of the PR `quality` workflow
/// (`SPEC/program/e2e-integration-tests.md` § CI — `app_e2e_linux` lane
/// is a no-op), the widget-test layer carries the behavioural pins for
/// the AC1 "single canonical shared helper" and AC10 "no silent flakiness
/// from divergent post-sheet-close cleanup" contracts. Without these
/// pins, a future refactor of the per-opener cleanup body that broke
/// byte-equivalence between civilian and naval (for example dropping the
/// post-close rail-hit-testable wait, or shortening the sheet-clear cap)
/// could silently regress at the integration-test wall-clock layer with
/// no unit-level signal.
///
/// Refs GitHub #2336 (AC1 — shared helpers; AC2 — single canonical
/// implementation; AC10 — no silent flakiness from timeout / divergence
/// regressions).
library;

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_helpers.dart';
import '../integration_test/e2e_test_shared.dart';

const _kPrimaryKey = ValueKey<String>('e2e_cpos_primary');
const _kSecondaryKey = ValueKey<String>('e2e_cpos_secondary');

void main() {
  suppressLogsForTests();

  testWidgets('e2eClosePanelOpenerSheetAndAwaitOpener short-circuits when no '
      'BottomSheet is mounted and the primary opener is already hit-testable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: _PrimaryHitTestableHarness()),
    );
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byKey(_kPrimaryKey).hitTestable(), findsOneWidget);
    final sw = Stopwatch()..start();
    await e2eClosePanelOpenerSheetAndAwaitOpener(
      tester,
      primary: find.byKey(_kPrimaryKey),
      secondary: find.byKey(_kSecondaryKey),
      afterSheetClearPhase: 'pump_until_sheet_cleared_test',
      awaitOpenerPhase: 'pump_until_opener_after_sheet_close_test',
    );
    expect(
      sw.elapsed < const Duration(milliseconds: 200),
      isTrue,
      reason:
          'When no sheet is mounted and the primary opener is already '
          'hit-testable, both inner pump-until-condition polls must '
          'short-circuit before their first idle pump so the no-sheet '
          'common case stays close to byte-equivalent to a raw '
          'fast-path probe (Refs GitHub #2336 AC1 fast path).',
    );
  });

  testWidgets(
    'e2eClosePanelOpenerSheetAndAwaitOpener closes a mounted BottomSheet '
    'and returns once the sheet leaves the tree',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: _PrimaryWithSheetTriggerHarness()),
      );
      expect(find.byKey(_kPrimaryKey).hitTestable(), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);

      // Open a modal bottom sheet covering the rail trigger.
      await tester.tap(find.text('open_sheet'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        find.byKey(_kPrimaryKey).hitTestable(),
        findsNothing,
        reason:
            'Test fixture must start with the primary trigger covered by '
            'the bottom sheet so the cleanup recipe is actually exercised.',
      );

      await e2eClosePanelOpenerSheetAndAwaitOpener(
        tester,
        primary: find.byKey(_kPrimaryKey),
        secondary: find.byKey(_kSecondaryKey),
        afterSheetClearPhase: 'pump_until_sheet_cleared_test',
        awaitOpenerPhase: 'pump_until_opener_after_sheet_close_test',
      );
      expect(
        find.byType(BottomSheet),
        findsNothing,
        reason:
            'After the helper completes, the bottom sheet must have left '
            'the tree (Refs GitHub #2336 AC1 — close + poll-until-empty).',
      );
      expect(
        find.byKey(_kPrimaryKey).hitTestable(),
        findsOneWidget,
        reason:
            'After the sheet dismisses, the helper must observe the rail '
            'becoming hit-testable so the outer opener loop can dispatch '
            'its next rail tap on a clean surface (Refs GitHub #2336 '
            'AC10 — no silent flakiness from off-screen-trigger drops).',
      );
    },
  );

  testWidgets(
    'e2eClosePanelOpenerSheetAndAwaitOpener does not throw when the rail '
    'remains hidden past the awaitOpenerTimeout (best-effort settle)',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      expect(find.byKey(_kPrimaryKey), findsNothing);
      expect(find.byKey(_kSecondaryKey), findsNothing);
      Object? caught;
      try {
        await e2eClosePanelOpenerSheetAndAwaitOpener(
          tester,
          primary: find.byKey(_kPrimaryKey),
          secondary: find.byKey(_kSecondaryKey),
          afterSheetClearPhase: 'pump_until_sheet_cleared_test',
          awaitOpenerPhase: 'pump_until_opener_after_sheet_close_test',
          awaitOpenerTimeout: const Duration(milliseconds: 100),
          sheetClearTimeout: const Duration(milliseconds: 100),
        );
      } catch (e) {
        caught = e;
      }
      expect(
        caught,
        isNull,
        reason:
            'Both inner polls delegate to e2ePumpUntilConditionOrIdle '
            'which is best-effort (no throw on timeout); a persistent '
            'absence of both rail/marker must defer to the outer opener '
            'loop rather than failing inside the cleanup helper, mirroring '
            'the pre-lift inline behaviour the civilian and naval openers '
            'have carried since the adaptive-polling refactor.',
      );
    },
  );

  testWidgets(
    'e2eClosePanelOpenerSheetAndAwaitOpener short-circuits the rail wait '
    'when only the secondary marker is hit-testable',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: _SecondaryOnlyHarness()));
      expect(find.byKey(_kPrimaryKey), findsNothing);
      expect(find.byKey(_kSecondaryKey).hitTestable(), findsOneWidget);
      final sw = Stopwatch()..start();
      await e2eClosePanelOpenerSheetAndAwaitOpener(
        tester,
        primary: find.byKey(_kPrimaryKey),
        secondary: find.byKey(_kSecondaryKey),
        afterSheetClearPhase: 'pump_until_sheet_cleared_test',
        awaitOpenerPhase: 'pump_until_opener_after_sheet_close_test',
      );
      expect(
        sw.elapsed < const Duration(milliseconds: 300),
        isTrue,
        reason:
            'When the secondary marker is already hit-testable, the '
            'rail/marker poll must short-circuit on the first predicate '
            'evaluation. A regression that only checked the primary '
            'would pay a 3 s timeout on every fleet-reach iteration that '
            'opens via the marker fallback (Refs GitHub #2336 AC1 / AC5).',
      );
    },
  );

  testWidgets('e2eClosePanelOpenerSheetAndAwaitOpener accepts a null secondary '
      '(future opener path)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: _PrimaryHitTestableHarness()),
    );
    await e2eClosePanelOpenerSheetAndAwaitOpener(
      tester,
      primary: find.byKey(_kPrimaryKey),
      afterSheetClearPhase: 'pump_until_sheet_cleared_test',
      awaitOpenerPhase: 'pump_until_opener_after_sheet_close_test',
    );
    expect(
      find.byKey(_kPrimaryKey).hitTestable(),
      findsOneWidget,
      reason:
          'When secondary is null the helper must poll on the primary '
          'alone without throwing on a missing marker finder; the '
          'parameter mirrors [e2eAwaitPanelOpenerRailHitTestable] so '
          'future openers without a map-marker concept can adopt this '
          'helper byte-equivalently (Refs GitHub #2336 AC1).',
    );
  });

  testWidgets(
    'AC1 barrel alias `closePanelOpenerSheetAndAwaitOpener` forwards to '
    'the shared implementation with the documented signature',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: _PrimaryHitTestableHarness()),
      );
      final Future<void> Function(
        WidgetTester, {
        required Finder primary,
        Finder? secondary,
        required String afterSheetClearPhase,
        required String awaitOpenerPhase,
        E2ePerfLog? perf,
        Duration bottomSheetCloseTimeout,
        Duration sheetClearTimeout,
        Duration awaitOpenerTimeout,
      })
      barrelTearOff = closePanelOpenerSheetAndAwaitOpener;
      await barrelTearOff(
        tester,
        primary: find.byKey(_kPrimaryKey),
        afterSheetClearPhase: 'pump_until_sheet_cleared_test',
        awaitOpenerPhase: 'pump_until_opener_after_sheet_close_test',
      );
      expect(
        find.byKey(_kPrimaryKey).hitTestable(),
        findsOneWidget,
        reason:
            'The AC1 barrel alias must accept the documented signature '
            'without an explicit cast so future scenarios can compose the '
            'recipe through the `e2e_helpers.dart` barrel like every '
            'other AC1 entry (Refs GitHub #2336 AC1 / AC2).',
      );
    },
  );
}

/// Harness with a single keyed primary trigger that is hit-testable on the
/// first pump (no overlay, no scrollable). Used by the short-circuit
/// fast-path tests above.
class _PrimaryHitTestableHarness extends StatelessWidget {
  const _PrimaryHitTestableHarness();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        key: _kPrimaryKey,
        onPressed: () {},
        child: const Text('Primary'),
      ),
    );
  }
}

/// Harness with only the secondary trigger rendered (primary is absent).
/// Mirrors the naval opener's `[marker, rail]` call site when the rail
/// button has not yet entered the tree.
class _SecondaryOnlyHarness extends StatelessWidget {
  const _SecondaryOnlyHarness();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        key: _kSecondaryKey,
        onPressed: () {},
        child: const Text('Secondary'),
      ),
    );
  }
}

/// Harness with a keyed primary trigger and a `open_sheet` text button
/// that pushes a modal [BottomSheet]. The test opens the sheet, asserts
/// the rail is covered, then exercises
/// [e2eClosePanelOpenerSheetAndAwaitOpener] which pops the sheet via
/// [tester.binding.handlePopRoute] (inside [e2eCloseBottomSheet]) and
/// awaits the rail becoming hit-testable again.
class _PrimaryWithSheetTriggerHarness extends StatelessWidget {
  const _PrimaryWithSheetTriggerHarness();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Center(
            child: TextButton(
              key: _kPrimaryKey,
              onPressed: () {},
              child: const Text('Primary'),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Builder(
              builder: (ctx) => TextButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: ctx,
                    builder: (_) => const SizedBox(
                      height: 400,
                      child: Center(child: Text('SheetBody')),
                    ),
                  );
                },
                child: const Text('open_sheet'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
