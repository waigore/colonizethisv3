// Widget/unit tests for BaseUnitsPanelState (Refs #3546).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';

import 'base_units_panel_harness.dart';

void main() {
  suppressLogsForTests();

  group('BaseUnitsPanelState selection dispatch', () {
    testWidgets('toggleSelection adds/removes ids and rebuilds', (tester) async {
      final state = await pumpBaseUnitsPanelHarness(
        tester,
        selectableIds: ['a', 'b'],
      );
      expect(state.isSelected('a'), isFalse);

      state.toggleSelection('a');
      await tester.pump();
      expect(state.isSelected('a'), isTrue);

      state.toggleSelection('a');
      await tester.pump();
      expect(state.isSelected('a'), isFalse);
    });

    testWidgets('selectAllOrClear selects all then clears', (tester) async {
      final state = await pumpBaseUnitsPanelHarness(
        tester,
        selectableIds: ['a', 'b'],
      );

      state.selectAllOrClear(['a', 'b']);
      await tester.pump();
      expect(state.selection.selectedIds, {'a', 'b'});

      state.selectAllOrClear(['a', 'b']);
      await tester.pump();
      expect(state.selection.isEmpty, isTrue);
    });

    testWidgets('clearSelection empties the store', (tester) async {
      final state = await pumpBaseUnitsPanelHarness(
        tester,
        selectableIds: ['a', 'b'],
      );
      state.selectAllOrClear(['a', 'b']);
      await tester.pump();

      state.clearSelection();
      await tester.pump();
      expect(state.selection.isEmpty, isTrue);
    });

    testWidgets('headerValueFor mirrors the controller tri-state', (
      tester,
    ) async {
      final state = await pumpBaseUnitsPanelHarness(
        tester,
        selectableIds: ['a', 'b'],
      );
      expect(state.headerValueFor(['a', 'b']), isFalse);

      state.toggleSelection('a');
      await tester.pump();
      expect(state.headerValueFor(['a', 'b']), isNull);

      state.toggleSelection('b');
      await tester.pump();
      expect(state.headerValueFor(['a', 'b']), isTrue);
    });
  });

  group('BaseUnitsPanelState.buildUnitsPanel action wiring', () {
    testWidgets('renders the select-all + Combine cluster when shown', (
      tester,
    ) async {
      await pumpBaseUnitsPanelHarness(tester, selectableIds: ['a', 'b']);

      expect(find.byType(Checkbox), findsOneWidget);
      final combine = tester.widget<CtActionTextButton>(
        find.byType(CtActionTextButton),
      );
      expect(combine.label, 'Combine');
      expect(combine.primary, isTrue);
    });

    testWidgets('omits the cluster when showCombineCluster is false', (
      tester,
    ) async {
      await pumpBaseUnitsPanelHarness(
        tester,
        selectableIds: ['a', 'b'],
        showCombineCluster: false,
      );

      expect(find.byType(Checkbox), findsNothing);
      expect(find.text('Combine'), findsNothing);
    });

    testWidgets('header checkbox value reflects current selection', (
      tester,
    ) async {
      final state = await pumpBaseUnitsPanelHarness(
        tester,
        selectableIds: ['a', 'b'],
      );
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

      state.selectAllOrClear(['a', 'b']);
      await tester.pump();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    });

    testWidgets('tapping the checkbox invokes onSelectAll and selects all', (
      tester,
    ) async {
      var selectAllTaps = 0;
      final state = await pumpBaseUnitsPanelHarness(
        tester,
        selectableIds: ['a', 'b'],
        onSelectAll: () => selectAllTaps++,
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(selectAllTaps, 1);
      expect(state.selection.selectedIds, {'a', 'b'});
    });

    testWidgets('Combine pill is disabled when canCombine is false', (
      tester,
    ) async {
      await pumpBaseUnitsPanelHarness(
        tester,
        selectableIds: ['a', 'b'],
        canCombine: false,
      );
      final combine = tester.widget<CtActionTextButton>(
        find.byType(CtActionTextButton),
      );
      expect(combine.enabled, isFalse);
      expect(combine.onPressed, isNull);
    });

    testWidgets('Combine pill invokes onCombine when enabled', (tester) async {
      var combined = 0;
      await pumpBaseUnitsPanelHarness(
        tester,
        selectableIds: ['a', 'b'],
        onCombine: () => combined++,
      );
      await tester.tap(find.text('Combine'));
      await tester.pump();
      expect(combined, 1);
    });

    testWidgets('orders leading → cluster → trailing actions left to right', (
      tester,
    ) async {
      await pumpBaseUnitsPanelHarness(
        tester,
        selectableIds: ['a', 'b'],
        leading: [const Icon(Icons.flag, key: Key('lead'))],
        trailing: [const Icon(Icons.add, key: Key('trail'))],
      );

      final leadX = tester.getTopLeft(find.byKey(const Key('lead'))).dx;
      final checkboxX = tester.getTopLeft(find.byType(Checkbox)).dx;
      final combineX = tester.getTopLeft(find.byType(CtActionTextButton)).dx;
      final trailX = tester.getTopLeft(find.byKey(const Key('trail'))).dx;

      expect(leadX, lessThan(checkboxX));
      expect(checkboxX, lessThan(combineX));
      expect(combineX, lessThan(trailX));
    });
  });

  group('AC5 — CivilianUnitsPanel divergence', () {
    test('CivilianUnitsPanel keeps the Riverpod ConsumerStatefulWidget '
        'convention (single-select, non-combinable)', () {
      final Object civilianPanels = <CivilianUnitsPanel>[];
      expect(
        civilianPanels is List<ConsumerStatefulWidget>,
        isTrue,
        reason: 'CivilianUnitsPanel must remain a ConsumerStatefulWidget',
      );
    });
  });
}
