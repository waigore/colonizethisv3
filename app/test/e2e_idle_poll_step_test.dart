import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_shared.dart';

void main() {
  suppressLogsForTests();

  test('E2E adaptive idle poll ramp climbs by 25ms and caps at 100ms', () {
    expect(e2eAdaptivePollRampAfterIdle(25), 50);
    expect(e2eAdaptivePollRampAfterIdle(50), 75);
    expect(e2eAdaptivePollRampAfterIdle(75), 100);
    expect(e2eAdaptivePollRampAfterIdle(100), 100);
    expect(e2eAdaptivePollRampAfterIdle(150), 100);
  });

  group('e2ePumpUntilFinderEmpty', () {
    testWidgets('returns immediately when finder matches nothing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await e2ePumpUntilFinderEmpty(
        tester,
        find.text('no_such_widget'),
        timeout: const Duration(seconds: 1),
      );
    });

    testWidgets('pumps until finder clears then returns', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: _DisappearingLabel()));
      expect(find.text('gone'), findsOneWidget);
      await tester.tap(find.text('hide'));
      await e2ePumpUntilFinderEmpty(
        tester,
        find.text('gone'),
        timeout: const Duration(seconds: 2),
      );
      expect(find.text('gone'), findsNothing);
    });
  });

  group('e2eNextIdlePollStepMs', () {
    test('doubles until cap at 500', () {
      expect(e2eNextIdlePollStepMs(25), 50);
      expect(e2eNextIdlePollStepMs(50), 100);
      expect(e2eNextIdlePollStepMs(400), 500);
      expect(e2eNextIdlePollStepMs(500), 500);
    });
  });
}

class _DisappearingLabel extends StatefulWidget {
  const _DisappearingLabel();

  @override
  State<_DisappearingLabel> createState() => _DisappearingLabelState();
}

class _DisappearingLabelState extends State<_DisappearingLabel> {
  bool _showGone = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (_showGone) const Text('gone'),
          TextButton(
            onPressed: () => setState(() => _showGone = false),
            child: const Text('hide'),
          ),
        ],
      ),
    );
  }
}
