import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';

void main() {
  suppressLogsForTests();

  Future<void> pumpTransferList(
    WidgetTester tester, {
    required void Function(Map<String, int> left, Map<String, int> right)
    onConfirm,
    bool Function(Map<String, int> left, Map<String, int> right)? canConfirm,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CtTransferList(
            leftTitle: 'Original',
            rightTitle: 'New',
            initialLeftCounts: const {'carrack': 2, 'fluyte': 1},
            onConfirm: onConfirm,
            canConfirm: canConfirm,
            confirmLabel: 'Confirm Split',
            leftEmptyLabel: 'No ships',
            rightEmptyLabel: 'No ships',
            totalLabelBuilder: (total) => 'Total: $total ships',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool buttonEnabled(WidgetTester tester, String label) {
    final button = tester.widget<CtNinePatchButton>(
      find.widgetWithText(CtNinePatchButton, label),
    );
    return button.enabled;
  }

  testWidgets('transfer controls disabled until an item is selected', (
    WidgetTester tester,
  ) async {
    await pumpTransferList(tester, onConfirm: (_, __) {});

    expect(buttonEnabled(tester, '<'), isFalse);
    expect(buttonEnabled(tester, '>'), isFalse);
    expect(buttonEnabled(tester, '<<'), isFalse);
    expect(buttonEnabled(tester, '>>'), isFalse);
  });

  testWidgets('selected item supports one and all transfers', (
    WidgetTester tester,
  ) async {
    await pumpTransferList(tester, onConfirm: (_, __) {});

    await tester.tap(find.text('carrack (2)').first);
    await tester.pump();

    await tester.tap(find.widgetWithText(CtNinePatchButton, '>'));
    await tester.pump();
    expect(find.text('carrack (1)'), findsNWidgets(2));

    await tester.tap(find.widgetWithText(CtNinePatchButton, '>>'));
    await tester.pump();
    expect(find.text('carrack (2)'), findsOneWidget);
    expect(find.text('carrack (1)'), findsNothing);

    await tester.tap(find.widgetWithText(CtNinePatchButton, '<'));
    await tester.pump();
    expect(find.text('carrack (1)'), findsNWidgets(2));
  });

  testWidgets('confirm enablement follows validation callback', (
    WidgetTester tester,
  ) async {
    await pumpTransferList(
      tester,
      onConfirm: (_, __) {},
      canConfirm: (left, right) {
        final leftTotal = left.values.fold(0, (sum, value) => sum + value);
        final rightTotal = right.values.fold(0, (sum, value) => sum + value);
        return leftTotal >= 1 && rightTotal > 0;
      },
    );

    expect(buttonEnabled(tester, 'Confirm Split'), isFalse);

    await tester.tap(find.text('fluyte (1)'));
    await tester.pump();
    await tester.tap(find.widgetWithText(CtNinePatchButton, '>>'));
    await tester.pump();

    expect(buttonEnabled(tester, 'Confirm Split'), isTrue);
  });

  testWidgets('confirm returns current left and right counts', (
    WidgetTester tester,
  ) async {
    Map<String, int>? confirmedLeft;
    Map<String, int>? confirmedRight;

    await pumpTransferList(
      tester,
      onConfirm: (left, right) {
        confirmedLeft = left;
        confirmedRight = right;
      },
    );

    await tester.tap(find.text('carrack (2)').first);
    await tester.pump();
    await tester.tap(find.widgetWithText(CtNinePatchButton, '>'));
    await tester.pump();

    await tester.tap(find.text('Confirm Split'));
    await tester.pumpAndSettle();

    expect(confirmedLeft, isNotNull);
    expect(confirmedRight, isNotNull);
    expect(confirmedLeft!['carrack'], 1);
    expect(confirmedRight!['carrack'], 1);
  });
}
