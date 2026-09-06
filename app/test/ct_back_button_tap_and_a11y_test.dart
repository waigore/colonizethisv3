// CtBackButton tap behaviour and accessibility tests (Refs #4734 Slice H).
// Visual contract: ct_back_button_test.dart.

import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'ct_back_button_test_support.dart';

void main() {
  suppressLogsForTests();

  group('CtBackButton tap behaviour', () {
    testWidgets('custom onPressed is invoked once per tap', (tester) async {
      var taps = 0;
      await pumpCtBackButton(
        tester,
        CtBackButton(onPressed: () => taps++),
      );
      await tester.tap(find.byType(CtBackButton));
      expect(taps, 1);
    });

    testWidgets(
      'null onPressed defaults to Navigator.maybePop()',
      (tester) async {
        await pumpCtBackButtonNavigatorPopHarness(tester);
        expect(find.byType(CtBackButton), findsOneWidget);

        await tester.tap(find.byType(CtBackButton));
        await tester.pumpAndSettle();
        expect(find.byType(CtBackButton), findsNothing);
      },
    );

    testWidgets('disabled does not invoke onPressed (negative path)', (
      tester,
    ) async {
      var taps = 0;
      await pumpCtBackButton(
        tester,
        CtBackButton(enabled: false, onPressed: () => taps++),
      );
      await tester.tap(find.byType(CtBackButton), warnIfMissed: false);
      expect(taps, 0);
    });
  });

  group('CtBackButton accessibility', () {
    testWidgets(
      'default semantic label is the R11a literal "Back"',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await pumpCtBackButton(tester, CtBackButton(onPressed: () {}));
        expect(find.bySemanticsLabel('Back'), findsOneWidget);
        handle.dispose();
      },
    );

    testWidgets(
      'custom semanticLabel replaces the default',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await pumpCtBackButton(
          tester,
          CtBackButton(
            onPressed: () {},
            semanticLabel: 'Return',
          ),
        );
        expect(find.bySemanticsLabel('Return'), findsOneWidget);
        expect(find.bySemanticsLabel('Back'), findsNothing);
        handle.dispose();
      },
    );
  });
}
