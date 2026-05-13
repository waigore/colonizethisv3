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
}
