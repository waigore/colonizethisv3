import 'package:flutter/material.dart';

import '../../../../../widgets/ct_action_text_button.dart';
import '../../../../../widgets/ct_circular_locate_button.dart';
import '../../../../../widgets/ct_danger_text_button.dart';
import '../../../../../widgets/ct_spacing.dart';
import 'units_entity_action_row.dart';
import 'units_panel_row_chrome.dart';

/// Layout helpers for [UnitsEntityActionRow] (Refs #4117 de-part).
extension UnitsEntityActionRowActions on UnitsEntityActionRow {
  Widget buildEntityActionRowLayout(BoxConstraints constraints) {
    final iconOnly = constraints.maxWidth < iconOnlyBreakpoint;
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: details),
        if (actions.isNotEmpty) ...[
          SizedBox(width: dense ? spacing : 8),
          Flexible(
            // Dense naval rows must bound the actions cluster so the inner
            // LayoutBuilder can switch to icon-only before labeled pills overflow
            // at 320 dp (Refs #4213 — Move + Mission + Split + Locate).
            fit: dense ? FlexFit.tight : FlexFit.loose,
            child: Align(
              alignment: Alignment.topRight,
              child: dense
                  ? LayoutBuilder(
                      builder: (context, denseConstraints) {
                        final denseIconOnly =
                            iconOnly ||
                            denseConstraints.maxWidth <
                                denseIconOnlyBreakpoint(actions.length);
                        return buildDenseActionsRow(
                          actions: actions,
                          forceIconOnly: denseIconOnly,
                        );
                      },
                    )
                  : buildDefaultActionsWrap(
                      actions: actions,
                      iconOnly: iconOnly,
                    ),
            ),
          ),
        ],
      ],
    );
    const padding = EdgeInsets.symmetric(
      horizontal: CtSpacing.m,
      vertical: 6,
    );
    if (!chrome) {
      return Padding(padding: padding, child: row);
    }
    return UnitsPanelRowChrome(
      margin: EdgeInsets.zero,
      padding: padding,
      child: row,
    );
  }

  static double denseIconOnlyBreakpoint(int actionCount) {
    return 90.0 * actionCount;
  }

  Widget buildDefaultActionsWrap({
    required List<UnitsEntityAction> actions,
    required bool iconOnly,
  }) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final action in actions)
          buildActionPill(action: action, forceIconOnly: iconOnly),
      ],
    );
  }

  Widget buildDenseActionsRow({
    required List<UnitsEntityAction> actions,
    required bool forceIconOnly,
  }) {
    final children = <Widget>[];
    for (var i = 0; i < actions.length; i++) {
      if (i > 0) {
        children.add(SizedBox(width: spacing));
      }
      children.add(
        buildActionPill(action: actions[i], forceIconOnly: forceIconOnly),
      );
    }
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
    if (forceIconOnly) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: row,
      );
    }
    return row;
  }

  Widget buildActionPill({
    required UnitsEntityAction action,
    required bool forceIconOnly,
  }) {
    final bool enabled = action.onPressed != null;
    if (action.iconOnly) {
      return CtCircularLocateButton(
        key: action.buttonKey,
        onPressed: action.onPressed,
        icon: action.icon,
        tooltip: action.tooltip,
        semanticLabel: action.label,
        enabled: enabled,
      );
    }
    if (action.variant == UnitsEntityActionVariant.danger) {
      return CtDangerTextButton(
        key: action.buttonKey,
        onPressed: action.onPressed,
        label: action.label,
        icon: action.icon,
        tooltip: action.tooltip,
        enabled: enabled,
        iconOnly: forceIconOnly,
      );
    }
    return CtActionTextButton(
      key: action.buttonKey,
      onPressed: action.onPressed,
      label: action.label,
      icon: action.icon,
      tooltip: action.tooltip,
      enabled: enabled,
      iconOnly: forceIconOnly,
    );
  }
}
