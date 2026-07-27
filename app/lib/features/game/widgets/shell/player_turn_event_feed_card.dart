import 'package:colonizethis_app_ui_chrome/colonizethis_app_ui_chrome.dart';
import 'package:flutter/material.dart';

import '../../../../config/constants.dart';
import '../../../../widgets/ct_gradients.dart';
import '../../screens/game/game_screen_shared.dart'
    show kGameMapWideProvinceSidePanelWidth;
import 'player_turn_event_feed.dart';

/// Floating, scrollable news card rendered on the in-game map stack when
/// the player toggles the newspaper button in [GameTabBar].
///
/// SPEC: `SPEC/ui/player-turn-event-feed.md`.
class PlayerTurnEventFeedCard extends StatelessWidget {
  const PlayerTurnEventFeedCard({
    super.key,
    required this.entries,
    required this.emptyLabel,
    this.narrow = false,
  });

  final List<PlayerTurnEventFeedEntry> entries;
  final String emptyLabel;

  /// When true, render the card at narrow-viewport measurements per
  /// `SPEC/ui/mobile-adaptation.md` § In-game shell (issue #2870 S3).
  final bool narrow;

  static const double borderWidth = 1;
  static const EdgeInsetsGeometry contentPadding = EdgeInsets.all(10);
  static const double maxContentHeight = 220;
  static const double narrowMinWidth = 180;
  static const double narrowMaxWidth = 260;
  static const double narrowViewportFraction = 0.5;

  /// Minimum tap-target height for tappable rows on narrow viewports.
  static const double narrowTappableRowMinHeight =
      CtEventFeedEntriesList.narrowTappableRowMinHeightDefault;

  static const Key surfaceKey = Key('player_turn_event_feed_card_surface');

  static double resolveNarrowWidth(double viewportWidth) {
    final double scaled = viewportWidth * narrowViewportFraction;
    if (scaled < narrowMinWidth) return narrowMinWidth;
    if (scaled > narrowMaxWidth) return narrowMaxWidth;
    return scaled;
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle bodyStyle = TextStyle(
      color: EditorialMonoclePalette.fg,
      fontSize: 13,
    );
    final TextStyle emptyStyle = TextStyle(
      color: EditorialMonoclePalette.muted,
      fontSize: 13,
      fontStyle: FontStyle.italic,
    );
    final double cardWidth = narrow
        ? resolveNarrowWidth(MediaQuery.sizeOf(context).width)
        : kGameMapWideProvinceSidePanelWidth;
    return SizedBox(
      width: cardWidth,
      child: DecoratedBox(
        key: surfaceKey,
        decoration: BoxDecoration(
          gradient: CtGradients.panelGradient,
          border: Border.all(
            color: EditorialMonoclePalette.accentDim,
            width: borderWidth,
          ),
        ),
        child: Padding(
          padding: contentPadding,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: maxContentHeight),
            child: entries.isEmpty
                ? Text(emptyLabel, style: emptyStyle)
                : CtEventFeedEntriesList(
                    entries: entries
                        .map(
                          (PlayerTurnEventFeedEntry e) => CtEventFeedEntry(
                            text: e.text,
                            onTap: e.onTap,
                            linkAffordance: e.linkAffordance,
                          ),
                        )
                        .toList(growable: false),
                    bodyStyle: bodyStyle,
                    narrowBreakpoint: kNarrowBreakpoint,
                  ),
          ),
        ),
      ),
    );
  }
}
