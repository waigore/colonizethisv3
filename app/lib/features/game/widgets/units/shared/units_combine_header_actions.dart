// Shared combine-cluster header actions for the combine-capable unit panels
// (`MilitaryUnitsPanel`, `NavalUnitsPanel`). Refs #3546 target state #2 (AC4).
//
// Both panels rendered the identical trailing cluster — a tri-state select-all
// [Checkbox] in a [Tooltip], a 4px gap, and the primary "Combine" pill — with
// only the tooltip strings differing. The cluster is returned as the same flat
// list of action widgets the panels previously inlined, so the
// `UnitsPanelShell` trailing layout (and its inter-action spacing) is
// byte-for-byte preserved.

import 'package:flutter/material.dart';

import '../../chrome/ct_action_text_button.dart';

/// Builds the shared select-all + Combine header action cluster.
///
/// Returned widgets are meant to be spread into a `UnitsPanelShell.actions`
/// list (the caller keeps its own `hasContent / !readOnly` guard). [headerValue]
/// is the [Checkbox] tri-state (`true` all, `false` none, `null` partial);
/// [onSelectAll] is invoked on any checkbox tap; the Combine pill is enabled
/// only when [canCombine] and then invokes [onCombine].
List<Widget> unitsCombineHeaderActions({
  required bool? headerValue,
  required String selectAllTooltip,
  required String deselectAllTooltip,
  required String combineLabel,
  required bool canCombine,
  required VoidCallback onSelectAll,
  required VoidCallback onCombine,
}) {
  return [
    Tooltip(
      message: headerValue == true ? deselectAllTooltip : selectAllTooltip,
      child: Checkbox(
        tristate: true,
        value: headerValue,
        onChanged: (_) => onSelectAll(),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    const SizedBox(width: 4),
    // Combine adopts the compact **primary** header pill
    // (`CtActionTextButton(primary: true)`) per the unit-panel specs and issue
    // #3514 owner decisions #5 / #15.
    CtActionTextButton(
      primary: true,
      onPressed: canCombine ? onCombine : null,
      enabled: canCombine,
      label: combineLabel,
    ),
  ];
}
