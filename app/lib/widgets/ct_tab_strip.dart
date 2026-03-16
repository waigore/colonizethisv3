import 'package:flutter/material.dart';

/// Pixel-art friendly tab strip (non-Material). Labels in a row; selected index
/// shows content in an [IndexedStack]. Use for overlays/panels where Material
/// TabBar does not fit the aesthetic.
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

  @override
  State<CtTabStrip> createState() => _CtTabStripState();
}

class _CtTabStripState extends State<CtTabStrip> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyle = theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.tabLabels.length, (i) {
              final selected = i == _selectedIndex;
              final bg = selected
                  ? colorScheme.primary.withValues(alpha: 0.25)
                  : colorScheme.surface.withValues(alpha: 0.5);
              final border = selected ? colorScheme.primary : colorScheme.outline;
              return Padding(
                padding: EdgeInsets.only(right: i < widget.tabLabels.length - 1 ? 4 : 0),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: bg,
                      border: Border.all(color: border, width: 1),
                    ),
                    child: DefaultTextStyle(
                      style: textStyle,
                      child: Text(widget.tabLabels[i]),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
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
}
