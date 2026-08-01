import 'package:flutter/material.dart';

import 'victory_screen_keys.dart';

/// Side-by-side standings + minimap on wide viewports when map data exists.
class VictoryStandingsMinimapLayout extends StatelessWidget {
  const VictoryStandingsMinimapLayout({
    super.key,
    required this.isWide,
    required this.standings,
    required this.minimap,
  });

  final bool isWide;
  final Widget standings;
  final Widget? minimap;

  @override
  Widget build(BuildContext context) {
    final map = minimap;
    if (map == null) {
      return standings;
    }
    if (isWide) {
      return Row(
        key: VictoryScreenKeys.standingsMinimapWideRowKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: standings),
          const SizedBox(width: 8),
          Expanded(child: map),
        ],
      );
    }
    return Column(
      key: VictoryScreenKeys.standingsMinimapNarrowColumnKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        standings,
        const SizedBox(height: 8),
        map,
      ],
    );
  }
}
