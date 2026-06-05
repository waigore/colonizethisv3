import 'package:flutter/material.dart';

import '../../../../../widgets/ct_nine_patch_button.dart';
import '../../../../../widgets/ct_spacing.dart';
import 'units_panel_row_chrome.dart';

/// Shared unit/fleet row layout:
/// - details on the left
/// - action buttons on the right, left-to-right
/// - icon-only action mode on narrow widths
///
/// `dense: true` switches the action buttons to the compact inline-pill
/// footprint specified by the naval-units mockup
/// (`SPEC/ui/mockups/UNIT30001-naval-units-panel.html` `.f-actions button`):
/// smaller padding, lower [CtNinePatchButton.minHeight], smaller icon size,
/// and a `Row` that cannot wrap onto a second line at the default panel
/// width. Individual [UnitsEntityAction] entries may opt into icon-only
/// rendering via [UnitsEntityAction.iconOnly] (e.g. the locate control on a
/// fleet row); icon-only entries still respect the `dense` footprint.
class UnitsEntityActionRow extends StatelessWidget {
  const UnitsEntityActionRow({
    super.key,
    required this.details,
    this.actions = const [],
    this.iconOnlyBreakpoint = 280,
    this.spacing = 6,
    this.dense = false,
  });

  final Widget details;
  final List<UnitsEntityAction> actions;
  final double iconOnlyBreakpoint;
  final double spacing;

  /// When `true`, every action button renders at the compact inline-pill
  /// footprint defined for the naval-units panel mockup. The actions cluster
  /// stays on a single horizontal line (no `Wrap`) so Move/Split/Locate are
  /// guaranteed not to break onto a second row at the default panel width
  /// (Refs #2866 S8 R25). Civilian/military rows keep the default
  /// `CtNinePatchButton` footprint.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconOnly = constraints.maxWidth < iconOnlyBreakpoint;
        return UnitsPanelRowChrome(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(
            horizontal: CtSpacing.m,
            vertical: 6,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: details),
              if (actions.isNotEmpty) ...[
                SizedBox(width: dense ? spacing : 8),
                Flexible(
                  fit: FlexFit.loose,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: dense
                        ? LayoutBuilder(
                            builder: (context, denseConstraints) {
                              // Dense Row cannot wrap; if the actions cluster
                              // alone is narrower than [denseIconOnlyBreakpoint]
                              // (label + icon footprint per the mockup), fall
                              // back to icon-only across the whole cluster so
                              // it stays on one line. R25 spec explicitly
                              // permits "Narrow icon-only fallback below the
                              // existing iconOnlyBreakpoint".
                              final denseIconOnly =
                                  iconOnly ||
                                  denseConstraints.maxWidth <
                                      _denseIconOnlyBreakpoint(actions.length);
                              return _buildDenseActionsRow(
                                actions: actions,
                                forceIconOnly: denseIconOnly,
                              );
                            },
                          )
                        : _buildDefaultActionsWrap(
                            actions: actions,
                            iconOnly: iconOnly,
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

  /// Heuristic per-action label+icon width used to decide when the dense
  /// actions cluster must collapse to icon-only to avoid wrapping. Sized so
  /// the default 3-action naval cluster (Move + Split + Locate icon) stays
  /// in label+icon mode at the spec'd 420–640 dp panel width but collapses
  /// at the test-host viewports that constrain the action cluster below
  /// ~150 dp.
  static double _denseIconOnlyBreakpoint(int actionCount) {
    return 70.0 * actionCount;
  }

  Widget _buildDefaultActionsWrap({
    required List<UnitsEntityAction> actions,
    required bool iconOnly,
  }) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      alignment: WrapAlignment.end,
      children: [
        for (final action in actions)
          Tooltip(
            message: action.tooltip,
            child: CtNinePatchButton(
              key: action.buttonKey,
              onPressed: action.onPressed,
              enabled: action.onPressed != null,
              padding: EdgeInsets.symmetric(
                horizontal: iconOnly || action.iconOnly ? CtSpacing.m : 10,
                vertical: 6,
              ),
              minHeight: 32,
              child: iconOnly || action.iconOnly
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
    );
  }

  Widget _buildDenseActionsRow({
    required List<UnitsEntityAction> actions,
    required bool forceIconOnly,
  }) {
    final children = <Widget>[];
    for (var i = 0; i < actions.length; i++) {
      if (i > 0) {
        children.add(SizedBox(width: spacing));
      }
      final action = actions[i];
      final renderAsIconOnly = forceIconOnly || action.iconOnly;
      children.add(
        Tooltip(
          message: action.tooltip,
          child: CtNinePatchButton(
            key: action.buttonKey,
            onPressed: action.onPressed,
            enabled: action.onPressed != null,
            // Mockup `.f-actions button { padding:3px 7px; font-size:9px; }` /
            // `.locate-btn { width:22px; height:22px; }` — keep the dense
            // pills tappable (>=24 dp) while shaving the inherited 32 dp
            // default `CtNinePatchButton` height.
            padding: EdgeInsets.symmetric(
              horizontal: renderAsIconOnly ? 4 : 7,
              vertical: 3,
            ),
            minHeight: 24,
            child: renderAsIconOnly
                ? Icon(action.icon, size: 14)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(action.icon, size: 14),
                      const SizedBox(width: 3),
                      Text(action.label),
                    ],
                  ),
          ),
        ),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

class UnitsEntityAction {
  const UnitsEntityAction({
    required this.tooltip,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconOnly = false,
    this.buttonKey,
  });

  final String tooltip;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  /// Stable [Key] applied to the rendered action button regardless of whether
  /// it renders `Icon + label` or collapses to icon-only. Lets e2e helpers
  /// locate the control deterministically when the label [Text] is suppressed
  /// at narrow viewports (Refs #2336; `colonizethis-e2e-ui-stability.mdc`).
  final Key? buttonKey;

  /// When `true`, the action button suppresses its text label and renders
  /// only the [icon] — used by the right-aligned locate control on naval
  /// fleet rows (mockup `.f-actions .locate-btn`). When `false`, the
  /// button shows `Icon + label` unless the row falls below
  /// [UnitsEntityActionRow.iconOnlyBreakpoint] (default-mode rows only).
  final bool iconOnly;
}
