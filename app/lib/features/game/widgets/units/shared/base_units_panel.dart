// Shared `State` base for the combine-capable unit panels
// (`MilitaryUnitsPanel`, `NavalUnitsPanel`). Refs #3546 target state #2 (AC4 /
// AC5).
//
// PR #3557 (Refs #3546) extracted the selection *store*
// (`UnitsMultiSelectionController`) and the combine-cluster *action widgets*
// (`unitsCombineHeaderActions`) used by both panels. The panels still each
// re-declared the same controller field, the same `setState`-wrapped selection
// dispatch (`toggle` / `selectAllOrClear`), and the same `build`-time assembly
// of the trailing select-all + Combine cluster into a `UnitsPanelShell`.
//
// [BaseUnitsPanelState] is the `BaseUnitsPanel<T>` abstraction the issue calls
// for, realised as a `State` mixin-style base (the idiomatic Flutter home for
// shared per-panel mutable selection state): it owns the controller, exposes
// the `setState`-wrapped dispatch the panels share, and provides
// [buildUnitsPanel] which composes the leading actions, the optional combine
// cluster, and the trailing actions into a `UnitsPanelShell` with the exact
// action ordering and spacing the panels rendered before.
//
// `CivilianUnitsPanel` deliberately does **not** extend this base (AC5): it is
// a Riverpod `ConsumerStatefulWidget` (it reads
// `availableWorkTargetIdsForUnitProvider`) with a single-id selection
// (`String? _selectedUnitId`) and no combine affordance, so neither the
// multi-id controller nor the combine-cluster builder applies. Forcing it onto
// this base would add a multi-selection store it never reads and a combine
// header it never shows. The two combine-capable panels are plain
// `StatefulWidget`s, so the shared convention here is `State<W>`.
library;

import 'package:flutter/material.dart';

import 'units_combine_header_actions.dart';
import 'units_multi_selection_controller.dart';
import 'units_panel_shell.dart';

/// Shared selection-dispatch + panel-shell assembly base for the
/// combine-capable unit panels.
///
/// [W] is the concrete panel widget type (`MilitaryUnitsPanel` /
/// `NavalUnitsPanel`). Subclasses own their tree building and per-row action
/// wiring; this base owns the multi-selection store and the trailing
/// select-all + Combine header cluster so that dispatch and action wiring stay
/// in one place.
abstract class BaseUnitsPanelState<W extends StatefulWidget> extends State<W> {
  /// Set-backed multi-selection store shared by the combine-capable panels.
  ///
  /// Subclasses derive the canonical selection id per row (army id, or the
  /// home-fleet id for the Home Fleet) and pass it to [toggleSelection] /
  /// [selectAllOrClear] and read membership via [isSelected].
  final UnitsMultiSelectionController selection = UnitsMultiSelectionController();

  /// Adds [id] when absent / removes it when present, inside [setState].
  void toggleSelection(String id) => setState(() => selection.toggle(id));

  /// Select-all header behaviour for [allIds] (select all, else clear when all
  /// already selected), inside [setState].
  void selectAllOrClear(Iterable<String> allIds) =>
      setState(() => selection.selectAllOrClear(allIds));

  /// Clears the entire selection inside [setState].
  void clearSelection() => setState(selection.clear);

  /// Whether [id] is currently selected.
  bool isSelected(String id) => selection.contains(id);

  /// Header checkbox tri-state for [allIds] (`true` all / `false` none /
  /// `null` partial). See [UnitsMultiSelectionController.headerValue].
  bool? headerValueFor(Iterable<String> allIds) =>
      selection.headerValue(allIds);

  /// Assembles the panel's [UnitsPanelShell], composing [leadingActions], the
  /// optional select-all + Combine cluster, and [trailingActions] into the top
  /// bar's trailing slot.
  ///
  /// When [showCombineCluster] is true the cluster is inserted between leading
  /// and trailing actions with the same widgets and ordering the panels
  /// inlined before (see [unitsCombineHeaderActions]); the header tri-state is
  /// derived from [selectableIds]. Passing [panelConstraints] overrides the
  /// shell's default size (naval scales on wide viewports); omit it for the
  /// default panel constraints.
  @protected
  Widget buildUnitsPanel({
    required String title,
    List<Widget> leadingActions = const <Widget>[],
    required bool showCombineCluster,
    required Iterable<String> selectableIds,
    required String selectAllTooltip,
    required String deselectAllTooltip,
    required String combineLabel,
    required bool canCombine,
    required VoidCallback onSelectAll,
    required VoidCallback onCombine,
    List<Widget> trailingActions = const <Widget>[],
    required bool hasContent,
    required List<Widget> listChildren,
    required String emptyMessage,
    BoxConstraints? panelConstraints,
  }) {
    return UnitsPanelShell(
      title: title,
      actions: <Widget>[
        ...leadingActions,
        if (showCombineCluster)
          ...unitsCombineHeaderActions(
            headerValue: selection.headerValue(selectableIds),
            selectAllTooltip: selectAllTooltip,
            deselectAllTooltip: deselectAllTooltip,
            combineLabel: combineLabel,
            canCombine: canCombine,
            onSelectAll: onSelectAll,
            onCombine: onCombine,
          ),
        ...trailingActions,
      ],
      hasContent: hasContent,
      listChildren: listChildren,
      emptyMessage: emptyMessage,
      panelConstraints:
          panelConstraints ?? UnitsPanelShell.defaultPanelConstraints,
    );
  }
}
