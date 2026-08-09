import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_transfer_list.dart';

import '../app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  Future<void> pumpTransferList(
    WidgetTester tester, {
    required void Function(Map<String, int> left, Map<String, int> right)
    onConfirm,
    bool Function(Map<String, int> left, Map<String, int> right)? canConfirm,
    Map<String, int> initialLeftCounts = const {'carrack': 2, 'fluyte': 1},
  }) async {
    await tester.pumpWidget(
      buildAppShell(
        child: Scaffold(
          body: CtTransferList(
            leftTitle: 'Original',
            rightTitle: 'New',
            initialLeftCounts: initialLeftCounts,
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

  bool buttonEnabled(WidgetTester tester, Finder finder) {
    final button = tester.widget<CtNinePatchButton>(finder);
    return button.enabled;
  }

  testWidgets(
    'repeated single moves transfer exactly one per tap (3 identical items)',
    (WidgetTester tester) async {
      await pumpTransferList(
        tester,
        onConfirm: (_, _) {},
        initialLeftCounts: const {'carrack': 3},
      );

      await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne('carrack')));
      await tester.pump();
      expect(find.text('carrack (2)'), findsOneWidget);
      expect(find.text('carrack (1)'), findsOneWidget);

      await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne('carrack')));
      await tester.pump();
      expect(find.text('carrack (1)'), findsOneWidget);
      expect(find.text('carrack (2)'), findsOneWidget);

      await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('carrack')));
      await tester.pump();
      expect(find.text('carrack (3)'), findsOneWidget);
      expect(find.text('carrack (2)'), findsNothing);
      expect(find.text('carrack (1)'), findsNothing);
    },
  );

  testWidgets('per-row controls move one and all without selection', (
    WidgetTester tester,
  ) async {
    await pumpTransferList(tester, onConfirm: (_, _) {});

    await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne('carrack')));
    await tester.pump();
    expect(find.text('carrack (1)'), findsNWidgets(2));

    await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('carrack')));
    await tester.pump();
    expect(find.text('carrack (2)'), findsOneWidget);
    expect(find.text('carrack (1)'), findsNothing);

    await tester.tap(find.byKey(CtTransferListKeys.rightMoveOne('carrack')));
    await tester.pump();
    expect(find.text('carrack (1)'), findsNWidgets(2));
  });

  testWidgets('<< on new side moves entire type back in one action', (
    WidgetTester tester,
  ) async {
    await pumpTransferList(
      tester,
      onConfirm: (_, _) {},
      initialLeftCounts: const {'carrack': 2, 'galleon': 1},
    );

    await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne('carrack')));
    await tester.pump();
    await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('carrack')));
    await tester.pump();
    expect(find.text('carrack (2)'), findsOneWidget);
    expect(find.text('galleon (1)'), findsOneWidget);

    await tester.tap(find.byKey(CtTransferListKeys.rightMoveAll('carrack')));
    await tester.pump();
    expect(find.text('carrack (2)'), findsOneWidget);
    expect(find.text('galleon (1)'), findsOneWidget);
    expect(find.text('carrack (1)'), findsNothing);
  });

  testWidgets('confirm enablement follows validation callback', (
    WidgetTester tester,
  ) async {
    await pumpTransferList(
      tester,
      onConfirm: (_, _) {},
      canConfirm: (left, right) {
        final leftTotal = left.values.fold(0, (sum, value) => sum + value);
        final rightTotal = right.values.fold(0, (sum, value) => sum + value);
        return leftTotal >= 1 && rightTotal > 0;
      },
    );

    expect(
      buttonEnabled(
        tester,
        find.widgetWithText(CtNinePatchButton, 'Confirm Split'),
      ),
      isFalse,
    );

    await tester.tap(find.byKey(CtTransferListKeys.leftMoveAll('fluyte')));
    await tester.pump();

    expect(
      buttonEnabled(
        tester,
        find.widgetWithText(CtNinePatchButton, 'Confirm Split'),
      ),
      isTrue,
    );
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

    await tester.tap(find.byKey(CtTransferListKeys.leftMoveOne('carrack')));
    await tester.pump();

    await tester.tap(find.text('Confirm Split'));
    await tester.pumpAndSettle();

    expect(confirmedLeft, isNotNull);
    expect(confirmedRight, isNotNull);
    expect(confirmedLeft!['carrack'], 1);
    expect(confirmedRight!['carrack'], 1);
  });
}
