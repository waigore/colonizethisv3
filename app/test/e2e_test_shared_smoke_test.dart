import 'package:colonizethis_app/config/ct_e2e.dart';
import 'package:colonizethis_app/l10n/app_localizations_lookup.dart';
import 'package:colonizethis_app/widgets/ct_choice_chip.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

void main() {
  suppressLogsForTests();
  test('e2eAdaptivePollRampAfterIdle ramps under 100ms then caps', () {
    expect(e2eAdaptivePollRampAfterIdle(25), 50);
    expect(e2eAdaptivePollRampAfterIdle(75), 100);
    expect(e2eAdaptivePollRampAfterIdle(100), 100);
  });

  test('e2eNextIdlePollStepMs doubles until max cap', () {
    expect(e2eNextIdlePollStepMs(25), 50);
    expect(e2eNextIdlePollStepMs(250), 500);
    expect(e2eNextIdlePollStepMs(500), 500);
  });

  testWidgets('e2ePumpUntilFinderEmpty returns immediately when finder empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final sw = Stopwatch()..start();
    await e2ePumpUntilFinderEmpty(
      tester,
      find.byType(SnackBar),
      timeout: const Duration(seconds: 2),
    );
    expect(sw.elapsed, lessThan(const Duration(milliseconds: 50)));
  });

  testWidgets('e2eCollectTextPreorder walks subtree in preorder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text('alpha'),
              Row(children: [Text('beta')]),
            ],
          ),
        ),
      ),
    );
    final root = tester.element(find.byType(Column));
    final lines = <String>[];
    e2eCollectTextPreorder(root, lines);
    expect(lines, ['alpha', 'beta']);
  });

  testWidgets('e2ePumpUntil succeeds when condition is already true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    var calls = 0;
    await e2ePumpUntil(
      tester,
      () {
        calls++;
        return true;
      },
      timeout: const Duration(seconds: 1),
      phaseName: 'smoke_immediate',
    );
    expect(calls, 1);
  });

  testWidgets('e2ePumpUntilConditionOrIdle succeeds before first pump', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final met = await e2ePumpUntilConditionOrIdle(
      tester,
      () => true,
      timeout: const Duration(seconds: 1),
      phaseName: 'smoke_condition_idle_immediate',
    );
    expect(met, isTrue);
  });

  testWidgets('e2ePumpUntilConditionOrIdle returns false when timeout elapses', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final met = await e2ePumpUntilConditionOrIdle(
      tester,
      () => false,
      timeout: const Duration(milliseconds: 60),
      phaseName: 'smoke_condition_idle_timeout',
    );
    expect(met, isFalse);
  });

  testWidgets('e2eOldWorldRegionChipAppearsSelected reads CtChoiceChip', (
    WidgetTester tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CtChoiceChip(
            label: Text(l10n.region_oldWorld),
            selected: true,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    expect(e2eOldWorldRegionChipAppearsSelected(l10n), isTrue);
  });

  testWidgets('e2eNewWorldRegionChipAppearsSelected reads keyed subtree', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KeyedSubtree(
            key: kCtE2ERegionTabNewWorldKey,
            child: CtChoiceChip(
              label: const Text('New World'),
              selected: true,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(e2eNewWorldRegionChipAppearsSelected(), isTrue);
  });

  testWidgets('e2eCloseBottomSheet no-ops when no bottom sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await e2eCloseBottomSheet(tester);
  });

  testWidgets('e2eDismissTransientUi no-ops on empty scaffold', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await e2eDismissTransientUi(tester);
  });

  testWidgets('e2ePumpFor completes (zero and non-zero virtual time)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await e2ePumpFor(tester, Duration.zero);
    await e2ePumpFor(tester, const Duration(milliseconds: 80));
    expect(find.byType(SizedBox), findsOneWidget);
  });

  test('E2ePerfLog bumpCounter and timing are safe to call', () {
    final log = E2ePerfLog('smoke');
    log.bumpCounter('a');
    log.bumpCounter('a', by: 2);
    log.timing('p', const Duration(milliseconds: 12));
  });

  testWidgets(
    'e2ePumpUntilConditionOrIdle returns true immediately when condition is already true',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final sw = Stopwatch()..start();
      final result = await e2ePumpUntilConditionOrIdle(
        tester,
        () => true,
        timeout: const Duration(seconds: 5),
      );
      expect(result, isTrue);
      expect(
        sw.elapsed < const Duration(milliseconds: 200),
        isTrue,
        reason:
            'Pre-pump short-circuit must keep already-true callers from '
            'paying any adaptive pump time (#2336 AC5).',
      );
    },
  );

  testWidgets(
    'e2ePumpUntilConditionOrIdle returns false on timeout without throwing',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final result = await e2ePumpUntilConditionOrIdle(
        tester,
        () => false,
        timeout: const Duration(milliseconds: 150),
      );
      expect(
        result,
        isFalse,
        reason:
            'Best-effort variant must not call fail() on timeout so callers '
            'can treat the wait as optional post-tap settle (#2336 AC5).',
      );
    },
  );

  testWidgets(
    'e2ePumpUntilConditionOrIdle returns true once condition flips during pump',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      var pumps = 0;
      final result = await e2ePumpUntilConditionOrIdle(
        tester,
        () {
          pumps++;
          return pumps >= 3;
        },
        timeout: const Duration(seconds: 2),
      );
      expect(result, isTrue);
      expect(
        pumps >= 3,
        isTrue,
        reason:
            'Condition must be evaluated at least once per polling step until '
            'it returns true (#2336 AC5).',
      );
    },
  );
}
