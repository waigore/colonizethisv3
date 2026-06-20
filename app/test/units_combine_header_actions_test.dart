// Widget tests for the shared combine-cluster header builder extracted from the
// military / naval unit panels (Refs #3546 AC4 / AC10).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/chrome/ct_action_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/units_combine_header_actions.dart';

Future<void> _pumpActions(
  WidgetTester tester, {
  required bool? headerValue,
  required bool canCombine,
  VoidCallback? onSelectAll,
  VoidCallback? onCombine,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Row(
          mainAxisSize: MainAxisSize.min,
          children: unitsCombineHeaderActions(
            headerValue: headerValue,
            selectAllTooltip: 'Select all',
            deselectAllTooltip: 'Deselect all',
            combineLabel: 'Combine',
            canCombine: canCombine,
            onSelectAll: onSelectAll ?? () {},
            onCombine: onCombine ?? () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  group('unitsCombineHeaderActions', () {
    testWidgets('renders a tri-state checkbox plus a primary Combine pill', (
      tester,
    ) async {
      await _pumpActions(tester, headerValue: false, canCombine: false);

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.tristate, isTrue);
      expect(checkbox.value, isFalse);

      final combine = tester.widget<CtActionTextButton>(
        find.byType(CtActionTextButton),
      );
      expect(combine.label, 'Combine');
      expect(combine.primary, isTrue);
    });

    testWidgets('shows the select-all tooltip when not fully selected', (
      tester,
    ) async {
      await _pumpActions(tester, headerValue: null, canCombine: false);
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Select all');
    });

    testWidgets('shows the deselect-all tooltip when fully selected', (
      tester,
    ) async {
      await _pumpActions(tester, headerValue: true, canCombine: false);
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Deselect all');
    });

    testWidgets('tapping the checkbox invokes onSelectAll', (tester) async {
      var taps = 0;
      await _pumpActions(
        tester,
        headerValue: false,
        canCombine: false,
        onSelectAll: () => taps++,
      );
      await tester.tap(find.byType(Checkbox));
      expect(taps, 1);
    });

    testWidgets('Combine pill is disabled when canCombine is false', (
      tester,
    ) async {
      await _pumpActions(tester, headerValue: null, canCombine: false);
      final combine = tester.widget<CtActionTextButton>(
        find.byType(CtActionTextButton),
      );
      expect(combine.onPressed, isNull);
      expect(combine.enabled, isFalse);
    });

    testWidgets('Combine pill invokes onCombine when enabled', (tester) async {
      var combined = 0;
      await _pumpActions(
        tester,
        headerValue: true,
        canCombine: true,
        onCombine: () => combined++,
      );
      final combine = tester.widget<CtActionTextButton>(
        find.byType(CtActionTextButton),
      );
      expect(combine.enabled, isTrue);
      await tester.tap(find.text('Combine'));
      expect(combined, 1);
    });
  });
}
