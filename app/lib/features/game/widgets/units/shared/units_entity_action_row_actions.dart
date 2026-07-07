part of 'units_entity_action_row.dart';

extension _UnitsEntityActionRowActions on UnitsEntityActionRow {
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
