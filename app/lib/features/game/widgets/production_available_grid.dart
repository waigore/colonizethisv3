import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';

/// Renders a fixed-column grid of `CtResourceCell`-shaped cells for the
/// Available subpanel (Refs #2862 S8b, owner decision **C7**).
///
/// Cells are laid out via `LayoutBuilder` + `Wrap` so each cell occupies a
/// `(maxWidth - (columnCount - 1) * spacing) / columnCount` slot. The trailing
/// row may be partially filled when `cells.length` is not a multiple of
/// [columnCount]; the remaining slot space is left empty so the grid keeps
/// equal column widths even when only one or two cells are present (e.g. a
/// Manufactured section with a single recipe output).
///
/// SPEC: `SPEC/ui/production-panel.md` § Layout — Available subpanel
/// "Commodity grid layout" / "Workers section".
class AvailableCellGrid extends StatelessWidget {
  const AvailableCellGrid({
    super.key,
    required this.columnCount,
    required this.cells,
  }) : assert(columnCount > 0);

  final int columnCount;
  final List<Widget> cells;

  static const double columnSpacing = 6;
  static const double rowSpacing = 4;

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final double cellWidth =
            (maxWidth - (columnCount - 1) * columnSpacing) / columnCount;
        final double effectiveCellWidth = cellWidth.isFinite && cellWidth > 0
            ? cellWidth
            : maxWidth;
        return Wrap(
          spacing: columnSpacing,
          runSpacing: rowSpacing,
          children: <Widget>[
            for (final Widget cell in cells)
              SizedBox(width: effectiveCellWidth, child: cell),
          ],
        );
      },
    );
  }
}

/// Right-aligned **Effective labour** total rendered with the dark
/// editorial-monocle accent color, monospace tabular figures, and a
/// 1px `--accent-dim` top border, per the issue #2862 Available subpanel
/// requirement R8 (right-aligned, accent color, bordered top).
class EffectiveLabourTotal extends StatelessWidget {
  const EffectiveLabourTotal({
    super.key,
    required this.text,
    required this.theme,
  });

  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final base = theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final style = base.copyWith(
      color: EditorialMonoclePalette.accent,
      fontWeight: FontWeight.w600,
      fontFamilyFallback: const <String>['SF Mono', 'Menlo', 'monospace'],
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: EditorialMonoclePalette.accentDim, width: 1),
        ),
      ),
      padding: const EdgeInsets.only(top: 4),
      child: Text(text, style: style, textAlign: TextAlign.right),
    );
  }
}
