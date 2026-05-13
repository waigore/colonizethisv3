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

  testWidgets(
    'e2ePumpUntilConditionOrIdle returns true immediately when condition is already true',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      var calls = 0;
      final result = await e2ePumpUntilConditionOrIdle(
        tester,
        () {
          calls++;
          return true;
        },
        timeout: const Duration(seconds: 1),
        phaseName: 'smoke_condition_immediate',
      );
      expect(result, isTrue);
      expect(calls, 1);
    },
  );

  testWidgets(
    'e2ePumpUntilConditionOrIdle returns false on timeout without throwing',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final result = await e2ePumpUntilConditionOrIdle(
        tester,
        () => false,
        timeout: const Duration(milliseconds: 80),
        phaseName: 'smoke_condition_timeout',
      );
      expect(result, isFalse);
    },
  );

  testWidgets(
    'e2ePumpUntilConditionOrIdle returns true once condition flips during pump',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: _E2eFlipStub()));
      final state = tester.state<_E2eFlipStubState>(find.byType(_E2eFlipStub));
      final result = await e2ePumpUntilConditionOrIdle(
        tester,
        () => state.ready,
        timeout: const Duration(seconds: 2),
        phaseName: 'smoke_condition_flip',
      );
      expect(result, isTrue);
      expect(state.ready, isTrue);
    },
  );
}

class _E2eFlipStub extends StatefulWidget {
  const _E2eFlipStub();

  @override
  State<_E2eFlipStub> createState() => _E2eFlipStubState();
}

class _E2eFlipStubState extends State<_E2eFlipStub> {
  bool ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          ready = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}
