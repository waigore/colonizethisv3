import 'package:flutter/material.dart';

import '../config/editorial_monocle_palette.dart';

/// One scrollable row in a turn-event feed card (Refs #4144).
class CtEventFeedEntry {
  const CtEventFeedEntry({
    required this.text,
    this.onTap,
    this.linkAffordance = false,
  });

  final String text;
  final VoidCallback? onTap;

  /// When true, the row shows a trailing chevron for screen-navigation taps.
  final bool linkAffordance;
}

/// Scrollable event rows with optional map-focus or route-navigation taps.
class CtEventFeedEntriesList extends StatelessWidget {
  const CtEventFeedEntriesList({
    super.key,
    required this.entries,
    required this.bodyStyle,
    required this.narrowBreakpoint,
    this.rowGap = rowGapDefault,
    this.tappableRowVerticalPadding = tappableRowVerticalPaddingDefault,
    this.narrowTappableRowMinHeight = narrowTappableRowMinHeightDefault,
  });

  final List<CtEventFeedEntry> entries;
  final TextStyle bodyStyle;

  /// Viewport widths below this use [narrowTappableRowMinHeight] tap targets.
  final double narrowBreakpoint;
  final double rowGap;
  final double tappableRowVerticalPadding;
  final double narrowTappableRowMinHeight;

  static const double rowGapDefault = 6;
  static const double tappableRowVerticalPaddingDefault = 2;

  /// Minimum tap-target height on narrow viewports
  /// (`SPEC/ui/mobile-adaptation.md` § 1).
  static const double narrowTappableRowMinHeightDefault = 44;

  @override
  Widget build(BuildContext context) {
    final bool narrowViewport =
        MediaQuery.sizeOf(context).width < narrowBreakpoint;
    return ListView.separated(
      shrinkWrap: true,
      itemCount: entries.length,
      separatorBuilder: (_, _) => SizedBox(height: rowGap),
      itemBuilder: (BuildContext context, int index) {
        final CtEventFeedEntry entry = entries[index];
        final Widget text = Text(entry.text, style: bodyStyle);
        final Widget rowContent = entry.linkAffordance
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: text),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: EditorialMonoclePalette.accentDim,
                  ),
                ],
              )
            : text;
        if (entry.onTap == null) {
          return rowContent;
        }
        final Widget tappableChild = Padding(
          padding: EdgeInsets.symmetric(vertical: tappableRowVerticalPadding),
          child: rowContent,
        );
        final Widget inkChild = narrowViewport
            ? ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: narrowTappableRowMinHeight,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: tappableChild,
                ),
              )
            : tappableChild;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: entry.onTap,
            splashColor: EditorialMonoclePalette.surfaceLite,
            highlightColor: EditorialMonoclePalette.surfaceLite,
            hoverColor: EditorialMonoclePalette.surfaceLite,
            child: inkChild,
          ),
        );
      },
    );
  }
}
