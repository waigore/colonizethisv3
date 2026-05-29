import 'package:flutter/material.dart';

import '../config/editorial_monocle_palette.dart';

/// Pixel-art friendly tab strip (non-Material). Labels in a row; selected index
/// shows content in an [IndexedStack]. Use for overlays/panels where Material
/// TabBar does not fit the aesthetic.
///
/// **Dark-theme visual contract (per `#2865` S3):**
/// Each tab label paints a 1 px rectangular frame with
/// [tabContentPadding] inner padding. The **selected** tab paints
/// [EditorialMonoclePalette.accentDim] at [selectedBackgroundAlpha] alpha
/// as the background, a 1 px [EditorialMonoclePalette.accent] border, and
/// label text in [EditorialMonoclePalette.accentBright]. **Unselected**
/// tabs paint [EditorialMonoclePalette.surface] at
/// [unselectedBackgroundAlpha] alpha, a 1 px
/// [EditorialMonoclePalette.accentDim] border, and label text in
/// [EditorialMonoclePalette.muted]. Adjacent tabs are separated by
/// [tabGap] px (no gap after the last tab). An [tabRowToBodyGap] px
/// vertical gap separates the tab row from the body [IndexedStack].
/// Catalog entry: `SPEC/ui/pixel-art-ui-catalog.md` § Pixel-art component
/// catalog (`CtTabStrip`).
class CtTabStrip extends StatefulWidget {
  CtTabStrip({
    super.key,
    required this.tabLabels,
    required this.tabViews,
    EdgeInsets? contentPadding,
  })  : assert(tabLabels.length == tabViews.length),
        assert(tabLabels.isNotEmpty),
        contentPadding = contentPadding ?? EdgeInsets.zero;

  final List<String> tabLabels;
  final List<Widget> tabViews;

  /// Padding around the tab content (IndexedStack).
  final EdgeInsets contentPadding;

  /// Inner padding applied to every tab label container.
  static const EdgeInsets tabContentPadding =
      EdgeInsets.symmetric(horizontal: 10, vertical: 6);

  /// Tab-label border width (1 px per dark-theme contract).
  static const double tabBorderWidth = 1;

  /// Selected-tab background alpha applied to
  /// [EditorialMonoclePalette.accentDim].
  static const double selectedBackgroundAlpha = 0.25;

  /// Unselected-tab background alpha applied to
  /// [EditorialMonoclePalette.surface].
  static const double unselectedBackgroundAlpha = 0.5;

  /// Horizontal gap between adjacent tabs (no gap after the last tab).
  static const double tabGap = 4;

  /// Vertical gap between the tab row and the body [IndexedStack].
  static const double tabRowToBodyGap = 8;

  @override
  State<CtTabStrip> createState() => _CtTabStripState();
}

class _CtTabStripState extends State<CtTabStrip> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle baseStyle =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(
              widget.tabLabels.length,
              (int i) => _buildTab(i, baseStyle),
            ),
          ),
        ),
        const SizedBox(height: CtTabStrip.tabRowToBodyGap),
        Expanded(
          child: Padding(
            padding: widget.contentPadding,
            child: IndexedStack(
              index: _selectedIndex,
              sizing: StackFit.expand,
              children: widget.tabViews,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int i, TextStyle baseStyle) {
    final bool selected = i == _selectedIndex;
    final Color background = selected
        ? EditorialMonoclePalette.accentDim
            .withValues(alpha: CtTabStrip.selectedBackgroundAlpha)
        : EditorialMonoclePalette.surface
            .withValues(alpha: CtTabStrip.unselectedBackgroundAlpha);
    final Color borderColor = selected
        ? EditorialMonoclePalette.accent
        : EditorialMonoclePalette.accentDim;
    final Color labelColor = selected
        ? EditorialMonoclePalette.accentBright
        : EditorialMonoclePalette.muted;
    final TextStyle labelStyle = baseStyle.copyWith(color: labelColor);
    final bool hasGap = i < widget.tabLabels.length - 1;
    return Padding(
      padding: EdgeInsets.only(right: hasGap ? CtTabStrip.tabGap : 0),
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = i),
        child: Container(
          padding: CtTabStrip.tabContentPadding,
          decoration: BoxDecoration(
            color: background,
            border: Border.all(
              color: borderColor,
              width: CtTabStrip.tabBorderWidth,
            ),
          ),
          child: DefaultTextStyle(
            style: labelStyle,
            child: Text(widget.tabLabels[i]),
          ),
        ),
      ),
    );
  }
}
