// Pump/decoration helpers for CtBackButton widget tests (Refs #4734 Slice H).

import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

Future<void> pumpCtBackButton(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    buildAppShell(
      child: Scaffold(
        body: Center(child: child),
      ),
    ),
  );
  await tester.pump();
}

AnimatedContainer ctBackButtonBodyContainer(WidgetTester tester) {
  return tester.widget<AnimatedContainer>(
    find.byKey(const ValueKey<String>('ctBackButtonBody')),
  );
}

Color ctBackButtonBodyColor(WidgetTester tester) {
  final AnimatedContainer container = ctBackButtonBodyContainer(tester);
  final BoxDecoration deco = container.decoration! as BoxDecoration;
  return deco.color!;
}

Icon ctBackButtonChevronIcon(WidgetTester tester) {
  return tester.widget<Icon>(
    find.descendant(
      of: find.byType(CtBackButton),
      matching: find.byIcon(Icons.chevron_left),
    ),
  );
}

Future<void> pumpCtBackButtonNavigatorPopHarness(WidgetTester tester) async {
  await tester.pumpWidget(
    buildAppShell(
      child: Builder(
        builder: (BuildContext context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(
                        body: Center(child: CtBackButton()),
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          );
        },
      ),
    ),
  );
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();
}

void expectCtBackButtonDisabledChrome(WidgetTester tester) {
  final Opacity opacity = tester.widget<Opacity>(
    find.descendant(
      of: find.byType(CtBackButton),
      matching: find.byType(Opacity),
    ),
  );
  expect(opacity.opacity, CtBackButton.disabledOpacity);
  expect(
    find.descendant(
      of: find.byType(CtBackButton),
      matching: find.byType(GestureDetector),
    ),
    findsNothing,
  );
  expect(
    find.descendant(
      of: find.byType(CtBackButton),
      matching: find.byType(MouseRegion),
    ),
    findsNothing,
  );
  expect(ctBackButtonBodyContainer(tester).duration, Duration.zero);
}
