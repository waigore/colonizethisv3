// Minimal harness panel for BaseUnitsPanelState tests (Refs #4734 Slice E, #3546).

import 'package:colonizethis_app/features/game/widgets/units/shared/base_units_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

class BaseUnitsPanelHarness extends StatefulWidget {
  const BaseUnitsPanelHarness({
    super.key,
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
  State<BaseUnitsPanelHarness> createState() => BaseUnitsPanelHarnessState();
}

class BaseUnitsPanelHarnessState extends BaseUnitsPanelState<BaseUnitsPanelHarness> {
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

Future<BaseUnitsPanelHarnessState> pumpBaseUnitsPanelHarness(
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
    buildAppShell(
      child: Scaffold(
        body: BaseUnitsPanelHarness(
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
  return tester.state<BaseUnitsPanelHarnessState>(
    find.byType(BaseUnitsPanelHarness),
  );
}
