import 'package:flutter/material.dart';

import '../../../../../config/editorial_monocle_palette.dart';
import '../../../../../widgets/ct_spacing.dart';

/// Expandable army / fleet row rendered as the mockup bordered gradient card
/// (issue #3514 owner decision #6; AC-6).
///
/// Wraps a Material [ExpansionTile] so the existing expand/collapse semantics
/// and the e2e helpers that detect expansion via the tile's
/// `RotationTransition` keep working, while replacing the bare
/// `ExpansionTile` Material chrome with the mockup `.unit-row` / `.fleet-row`
/// card (SPEC/ui/mockups/UNIT20001-military-units-panel.html `.unit-row`,
/// SPEC/ui/mockups/UNIT30001-naval-units-panel.html `.fleet-row`):
///
/// - **Collapsed:** vertical `--bg-deep` → `--surface` gradient with a 1 px
///   `--border` outline.
/// - **Expanded:** flat `--surface` fill with a 1 px `--accent-dim` outline
///   (mockup `.unit-row.expanded` / `.fleet-row.expanded`).
/// - **Expanded children:** separated from the header by a 1 px `--border`
///   top divider (mockup `.u-comp-table` / `.f-expanded` `border-top`).
///
/// The inner [ExpansionTile] is rendered transparent (no Material divider,
/// background fill, or shape border) so only this card's chrome is visible.
class UnitsEntityCard extends StatefulWidget {
  const UnitsEntityCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.initiallyExpanded = false,
  });

  /// Header content (the [UnitsEntityActionRow] title/actions cluster).
  final Widget title;

  /// Optional secondary line(s) below the title (location / mission / pending
  /// draft-move text).
  final Widget? subtitle;

  /// Detail content revealed when the card is expanded.
  final List<Widget> children;

  final bool initiallyExpanded;

  /// Vertical `--bg-deep` → `--surface` gradient that paints the collapsed
  /// card body, mirroring the mockup `.unit-row` / `.fleet-row`
  /// `linear-gradient(180deg,var(--bg-deep),var(--surface))`.
  static LinearGradient get collapsedGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          EditorialMonoclePalette.bgDeep,
          EditorialMonoclePalette.surface,
        ],
      );

  @override
  State<UnitsEntityCard> createState() => _UnitsEntityCardState();
}

class _UnitsEntityCardState extends State<UnitsEntityCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: CtSpacing.xs),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _expanded ? null : UnitsEntityCard.collapsedGradient,
          color: _expanded ? EditorialMonoclePalette.surface : null,
          border: Border.all(
            color: _expanded
                ? EditorialMonoclePalette.accentDim
                : EditorialMonoclePalette.border,
            width: 1,
          ),
        ),
        // Suppress the Material divider lines the ExpansionTile would paint
        // above/below its expanded children; the card border + child top
        // divider provide the mockup separators instead.
        child: Theme(
          data: baseTheme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: widget.title,
            subtitle: widget.subtitle,
            dense: true,
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            shape: const Border(),
            collapsedShape: const Border(),
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            expandedAlignment: Alignment.centerLeft,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            initiallyExpanded: widget.initiallyExpanded,
            onExpansionChanged: (value) => setState(() => _expanded = value),
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: EditorialMonoclePalette.border,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: widget.children,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
