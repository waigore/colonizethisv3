import 'package:flutter/material.dart';

import '../../../../../widgets/ct_nine_patch_button.dart';
import 'units_panel_row_chrome.dart';

/// Shared unit/fleet row layout:
/// - details on the left
/// - action buttons on the right, left-to-right
/// - icon-only action mode on narrow widths
class UnitsEntityActionRow extends StatelessWidget {
  const UnitsEntityActionRow({
    super.key,
    required this.details,
    this.actions = const [],
    this.iconOnlyBreakpoint = 280,
    this.spacing = 6,
  });

  final Widget details;
  final List<UnitsEntityAction> actions;
  final double iconOnlyBreakpoint;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconOnly = constraints.maxWidth < iconOnlyBreakpoint;
        return UnitsPanelRowChrome(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: details),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  fit: FlexFit.loose,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      alignment: WrapAlignment.end,
                      children: [
                        for (final action in actions)
                          Tooltip(
                            message: action.tooltip,
                            child: CtNinePatchButton(
                              onPressed: action.onPressed,
                              enabled: action.onPressed != null,
                              padding: EdgeInsets.symmetric(
                                horizontal: iconOnly ? 8 : 10,
                                vertical: 6,
                              ),
                              minHeight: 32,
                              child: iconOnly
                                  ? Icon(action.icon, size: 16)
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(action.icon, size: 16),
                                        const SizedBox(width: 4),
                                        Text(action.label),
                                      ],
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class UnitsEntityAction {
  const UnitsEntityAction({
    required this.tooltip,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
}
