import 'package:flutter/material.dart';

import '../../../../../widgets/ct_spacing.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_circular_locate_button.dart';
import 'package:colonizethis_app/widgets/ct_danger_text_button.dart';
import 'units_panel_row_chrome.dart';

part 'units_entity_action_row_actions.dart';

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
      builder: (context, constraints) =>
          buildEntityActionRowLayout(constraints),
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
