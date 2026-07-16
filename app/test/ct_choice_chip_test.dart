// Tests for CtChoiceChip. lib/widgets/ct_choice_chip.dart.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_choice_chip.dart';

import 'support/app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  testWidgets('CtChoiceChip builds and shows label', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildAppShell(
        child: Scaffold(
          body: CtChoiceChip(
            label: const Text('Option A'),
            selected: false,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Option A'), findsOneWidget);
  });

  testWidgets('CtChoiceChip tap calls onSelected with toggled value', (WidgetTester tester) async {
    bool? lastValue;
    await tester.pumpWidget(
      buildAppShell(
        child: Scaffold(
          body: CtChoiceChip(
            label: const Text('Option'),
            selected: false,
            onSelected: (v) => lastValue = v,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Option'));
    await tester.pump();
    expect(lastValue, isTrue);
  });

  testWidgets('CtChoiceChip when selected tap calls onSelected false', (WidgetTester tester) async {
    bool? lastValue;
    await tester.pumpWidget(
      buildAppShell(
        child: Scaffold(
          body: CtChoiceChip(
            label: const Text('Option'),
            selected: true,
            onSelected: (v) => lastValue = v,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Option'));
    await tester.pump();
    expect(lastValue, isFalse);
  });
}
