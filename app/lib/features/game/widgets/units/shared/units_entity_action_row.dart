import 'package:flutter/material.dart';

import '../../../../../widgets/ct_spacing.dart';
import '../../chrome/ct_action_text_button.dart';
import '../../chrome/ct_circular_locate_button.dart';
import '../../chrome/ct_danger_text_button.dart';
import 'units_panel_row_chrome.dart';

/// Shared unit/fleet row layout:
/// - details on the left
/// - action buttons on the right, left-to-right
/// - icon-only action mode on narrow widths
///
/// Row actions render with the mockup compact-pill family (issue #3514 owner
/// decision #6 — `SPEC/ui/mockups/UNIT20001-military-units-panel.html`
/// `.unit-row` / `UNIT30001-naval-units-panel.html` `.f-actions button`):
/// neutral actions use [CtActionTextButton], destructive
/// ([UnitsEntityActionVariant.danger]) actions use [CtDangerTextButton], and
/// per-action `iconOnly` controls (the right-end Locate pill) use the circular
/// [CtCircularLocateButton] (mockup `.locate-btn`).
///
/// `dense: true` switches the cluster to the naval inline footprint: a `Row`
/// that cannot wrap onto a second line at the default panel width. Individual
/// [UnitsEntityAction] entries may opt into icon-only rendering via
/// [UnitsEntityAction.iconOnly] (e.g. the locate control on a fleet/army row);
/// at narrow widths the remaining neutral/danger pills collapse to icon-only
/// via [CtActionTextButton.iconOnly] / [CtDangerTextButton.iconOnly].
class UnitsEntityActionRow extends StatelessWidget {
  const UnitsEntityActionRow({
    super.key,
    required this.details,
    this.actions = const [],
    this.iconOnlyBreakpoint = 280,
    this.spacing = 6,
    this.dense = false,
    this.chrome = true,
  });

  final Widget details;
  final List<UnitsEntityAction> actions;
  final double iconOnlyBreakpoint;
  final double spacing;

  /// When `true` (default), the row paints its own [UnitsPanelRowChrome]
  /// gradient + border surface — used by standalone rows. When `false`, the
  /// row renders only its inner padded `Row`; the surrounding chrome is
  /// supplied by an outer wrapper (the expandable [UnitsEntityCard] used by
  /// the military / naval panels), so the border is not double-painted.
  /// SPEC/ui/components/units-entity-action-row.md (issue #3514 AC-6).
  final bool chrome;

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
        final row = Row(
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
      },
    );
  }

  /// Heuristic per-action label+icon width used to decide when the dense
  /// actions cluster must collapse to icon-only to avoid overflowing the
  /// single inline row. Sized so the default 3-action naval cluster
  /// (Move + Split + Locate icon) stays in label+icon mode at the spec'd
  /// wide naval panel width (≥ ~528 dp content) but collapses to icon-only
  /// once the cluster's flex share drops below the combined label+icon
  /// footprint — including when the dense row is hosted inside the
  /// [UnitsEntityCard] mockup card chrome, where the actions cluster shares
  /// the title width ~50/50 with the row details and a bare label+icon
  /// pair (e.g. Move + Split with no locate on a tile-less at-sea fleet)
  /// would otherwise overflow its share by a few logical px (issue #3514
  /// naval card migration; SPEC/ui/components/units-entity-card.md).
  ///
  /// The `90` constant reflects the measured Cinzel-display label + 14 dp
  /// icon + 10 dp horizontal padding + 1 dp border footprint of a single
  /// compact pill plus inter-pill spacing, with a small margin so the
  /// collapse fires before the `RenderFlex` overflow rather than after it.
  static double _denseIconOnlyBreakpoint(int actionCount) {
    return 90.0 * actionCount;
  }

  Widget _buildDefaultActionsWrap({
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
          _buildActionPill(action: action, forceIconOnly: iconOnly),
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
      children.add(
        _buildActionPill(action: actions[i], forceIconOnly: forceIconOnly),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }

  /// Renders a single action as a mockup compact pill (issue #3514). Per-action
  /// [UnitsEntityAction.iconOnly] controls (the right-end Locate affordance)
  /// always render as the circular [CtCircularLocateButton]; the width-driven
  /// [forceIconOnly] collapse only suppresses the label on neutral/danger
  /// pills so Move / Split shrink to icon-only at narrow widths.
  Widget _buildActionPill({
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

/// Visual emphasis for a [UnitsEntityAction] when rendered with the mockup
/// compact-pill row-action family (issue #3514). [neutral] uses the standard
/// [CtActionTextButton] pill (mockup `.u-actions button` / `.f-actions
/// button`); [danger] uses the destructive [CtDangerTextButton] pill (mockup
/// `.u-actions .cancel-btn`).
///
/// Consumed by both the civilian row-action cluster
/// (`_CivilianUnitCardActions`) and the shared [UnitsEntityActionRow]
/// (military / naval rows) now that all three unit panels render the mockup
/// compact-pill row-action family.
enum UnitsEntityActionVariant { neutral, danger }

class UnitsEntityAction {
  const UnitsEntityAction({
    required this.tooltip,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconOnly = false,
    this.buttonKey,
    this.variant = UnitsEntityActionVariant.neutral,
  });

  final String tooltip;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  /// Visual emphasis (neutral vs destructive) used by mockup compact-pill
  /// row actions. Defaults to [UnitsEntityActionVariant.neutral].
  final UnitsEntityActionVariant variant;

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
