// Widget/unit tests for the shared `BaseUnitsPanelState` base extracted from the
// military / naval unit panels (Refs #3546 target state #2, AC4 / AC5 / AC10).
//
// AC4: the base centralises selection dispatch and the combine-cluster action
// wiring shared by the combine-capable panels.
// AC5: `CivilianUnitsPanel` deliberately does NOT use this base (it is a
// single-select, non-combinable `ConsumerStatefulWidget`); a structural test
// asserts the documented divergence.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/chrome/ct_action_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/shared/base_units_panel.dart';

/// Minimal panel exercising [BaseUnitsPanelState.buildUnitsPanel] and the shared
/// selection-dispatch surface without pulling in the full military/naval trees.
class _HarnessPanel extends StatefulWidget {
  const _HarnessPanel({
    required this.selectableIds,
    this.showCombineCluster = true,
    this.canCombine = true,
    this.leading = const <Widget>[],
    this.trailing = const <Widget>[],
    this.onSelectAll,
    this.onCombine,
  });

  final List<String> selectableIds;
  final bool showCombineCluster;
  final bool canCombine;
  final List<Widget> leading;
  final List<Widget> trailing;
  final VoidCallback? onSelectAll;
  final VoidCallback? onCombine;

  @override
  State<_HarnessPanel> createState() => _HarnessPanelState();
}

class _HarnessPanelState extends BaseUnitsPanelState<_HarnessPanel> {
  @override
  Widget build(BuildContext context) {
    return buildUnitsPanel(
      title: 'Test Panel',
      leadingActions: widget.leading,
      showCombineCluster: widget.showCombineCluster,
      selectableIds: widget.selectableIds,
      selectAllTooltip: 'Select all',
      deselectAllTooltip: 'Deselect all',
      combineLabel: 'Combine',
      canCombine: widget.canCombine,
      onSelectAll: () {
        widget.onSelectAll?.call();
        selectAllOrClear(widget.selectableIds);
      },
      onCombine: () => widget.onCombine?.call(),
      trailingActions: widget.trailing,
      hasContent: true,
      listChildren: const [Text('row')],
      emptyMessage: 'empty',
    );
  }
}

Future<_HarnessPanelState> _pumpHarness(
  WidgetTester tester, {
  required List<String> selectableIds,
  bool showCombineCluster = true,
  bool canCombine = true,
  List<Widget> leading = const <Widget>[],
  List<Widget> trailing = const <Widget>[],
  VoidCallback? onSelectAll,
  VoidCallback? onCombine,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _HarnessPanel(
          selectableIds: selectableIds,
          showCombineCluster: showCombineCluster,
          canCombine: canCombine,
          leading: leading,
          trailing: trailing,
          onSelectAll: onSelectAll,
          onCombine: onCombine,
        ),
      ),
    ),
  );
  return tester.state<_HarnessPanelState>(find.byType(_HarnessPanel));
}

void main() {
  suppressLogsForTests();

  group('BaseUnitsPanelState selection dispatch', () {
    testWidgets('toggleSelection adds/removes ids and rebuilds', (tester) async {
      final state = await _pumpHarness(tester, selectableIds: ['a', 'b']);
      expect(state.isSelected('a'), isFalse);

      state.toggleSelection('a');
      await tester.pump();
      expect(state.isSelected('a'), isTrue);

      state.toggleSelection('a');
      await tester.pump();
      expect(state.isSelected('a'), isFalse);
    });

    testWidgets('selectAllOrClear selects all then clears', (tester) async {
      final state = await _pumpHarness(tester, selectableIds: ['a', 'b']);

      state.selectAllOrClear(['a', 'b']);
      await tester.pump();
      expect(state.selection.selectedIds, {'a', 'b'});

      state.selectAllOrClear(['a', 'b']);
      await tester.pump();
      expect(state.selection.isEmpty, isTrue);
    });

    testWidgets('clearSelection empties the store', (tester) async {
      final state = await _pumpHarness(tester, selectableIds: ['a', 'b']);
      state.selectAllOrClear(['a', 'b']);
      await tester.pump();

      state.clearSelection();
      await tester.pump();
      expect(state.selection.isEmpty, isTrue);
    });

    testWidgets('headerValueFor mirrors the controller tri-state', (
      tester,
    ) async {
      final state = await _pumpHarness(tester, selectableIds: ['a', 'b']);
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
      await _pumpHarness(tester, selectableIds: ['a', 'b']);

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
      await _pumpHarness(
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
      final state = await _pumpHarness(tester, selectableIds: ['a', 'b']);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

      state.selectAllOrClear(['a', 'b']);
      await tester.pump();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    });

    testWidgets('tapping the checkbox invokes onSelectAll and selects all', (
      tester,
    ) async {
      var selectAllTaps = 0;
      final state = await _pumpHarness(
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
      await _pumpHarness(
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
      await _pumpHarness(
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
      await _pumpHarness(
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
      // Civilian rows are single-select and non-combinable, so the panel keeps
      // its `ConsumerStatefulWidget` convention and does not adopt the
      // multi-selection `BaseUnitsPanelState`. Asserted without instantiating
      // (which would require a full Game) via Dart's covariant generics; the
      // `Object`-typed reference keeps this a genuine runtime check.
      final Object civilianPanels = <CivilianUnitsPanel>[];
      expect(
        civilianPanels is List<ConsumerStatefulWidget>,
        isTrue,
        reason: 'CivilianUnitsPanel must remain a ConsumerStatefulWidget',
      );
    });
  });
}
