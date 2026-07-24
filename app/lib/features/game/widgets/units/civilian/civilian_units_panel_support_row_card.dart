/// Civilian unit row card chrome. SPEC/ui/civilian-units-panel.md.

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_circular_locate_button.dart';
import 'package:colonizethis_app/widgets/ct_danger_text_button.dart';
import '../../../../../widgets/ct_gap.dart';
import '../shared/units_entity_action_row.dart';

/// Bordered civilian-unit row card per `SPEC/ui/civilian-units-panel.md`
/// § Layout / wireframe → Row card chrome and mockup `.unit-row`
/// (Refs #2866 S9 R30).
///
/// Wraps the left detail stack and the right-aligned action cluster inside a
/// single `DecoratedBox` painted with a vertical
/// `EditorialMonoclePalette.bgDeep` → `EditorialMonoclePalette.surface`
/// gradient and a 1 dp border. The default border resolves to
/// [EditorialMonoclePalette.border]; pointer hover (via [MouseRegion]) and
/// tile-scope [selected] state both shift the border to
/// [EditorialMonoclePalette.accentDim] so the card surfaces selection /
/// pointer feedback without relying on Material `ListTile` chrome.
///
/// Public so widget tests can locate civilian rows via
/// `find.byType(CivilianUnitRowCard)` after the migration off `ListTile`.
class CivilianUnitRowCard extends StatefulWidget {
  const CivilianUnitRowCard({
    super.key,
    required this.details,
    required this.actions,
    required this.selected,
    required this.onTap,
  });

  final Widget details;
  final List<UnitsEntityAction> actions;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<CivilianUnitRowCard> createState() => _CivilianUnitRowCardState();
}

class _CivilianUnitRowCardState extends State<CivilianUnitRowCard> {
  bool _hovered = false;

  static const double _borderWidth = 1;
  static const double _innerSpacing = 8;
  static const double _minRowHeight = 44;

  Color _borderColor() {
    if (widget.selected || _hovered) {
      return EditorialMonoclePalette.accentDim;
    }
    return EditorialMonoclePalette.border;
  }

  static final LinearGradient _cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      EditorialMonoclePalette.bgDeep,
      EditorialMonoclePalette.surface,
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) {
          if (!_hovered) setState(() => _hovered = true);
        },
        onExit: (_) {
          if (_hovered) setState(() => _hovered = false);
        },
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: _cardGradient,
                border: Border.all(color: _borderColor(), width: _borderWidth),
              ),
              child: Padding(
                padding: const EdgeInsets.all(_innerSpacing),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: _minRowHeight),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: widget.details),
                      if (widget.actions.isNotEmpty) ...[
                        CtGap.wm,
                        _CivilianUnitCardActions(actions: widget.actions),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Right-aligned action cluster inside [CivilianUnitRowCard]. Renders the
/// mockup compact-pill row actions per `SPEC/ui/civilian-units-panel.md`
/// § Row actions and the `UNIT10001` mockup `.u-actions` family (issue #3514
/// owner decisions #6/#7):
///
/// - neutral actions (e.g. **Assign**) render as [CtActionTextButton] pills
///   with an icon + label (mockup `.u-actions button`),
/// - destructive actions ([UnitsEntityActionVariant.danger], e.g. **Cancel**)
///   render as [CtDangerTextButton] pills (mockup `.u-actions .cancel-btn`),
/// - `iconOnly` actions (the rightmost **Locate** control per R30) render as a
///   circular [CtCircularLocateButton] (mockup `.u-actions .locate-btn`).
///
/// The cluster stays a right-aligned [Wrap] so it flows onto a second line at
/// narrow widths rather than overflowing horizontally.
class _CivilianUnitCardActions extends StatelessWidget {
  const _CivilianUnitCardActions({required this.actions});

  final List<UnitsEntityAction> actions;

  static const double _spacing = 6;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: _spacing,
      runSpacing: _spacing,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [for (final action in actions) _buildAction(action)],
    );
  }

  Widget _buildAction(UnitsEntityAction action) {
    final bool enabled = action.onPressed != null;
    if (action.iconOnly) {
      return CtCircularLocateButton(
        onPressed: action.onPressed,
        icon: action.icon,
        tooltip: action.tooltip,
        semanticLabel: action.label,
        enabled: enabled,
      );
    }
    if (action.variant == UnitsEntityActionVariant.danger) {
      return CtDangerTextButton(
        onPressed: action.onPressed,
        label: action.label,
        icon: action.icon,
        tooltip: action.tooltip,
        enabled: enabled,
      );
    }
    return CtActionTextButton(
      onPressed: action.onPressed,
      label: action.label,
      icon: action.icon,
      tooltip: action.tooltip,
      enabled: enabled,
    );
  }
}
