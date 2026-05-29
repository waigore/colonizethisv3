import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../widgets/ct_gradients.dart';
import '../flame/game_screen_shared.dart'
    show kGameMapWideProvinceSidePanelWidth, kPlayerTurnFeedToggleButtonKey;

class PlayerTurnEventFeedEntry {
  const PlayerTurnEventFeedEntry({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;
}

/// Newspaper toggle for the human-player turn event feed; lives in the map
/// controls band inside [GameTabBar].
///
/// Implements `Refs #2861` S7 dark editorial-monocle restyle: the legacy
/// black/white Material chrome is replaced with a token-resolved gradient
/// surface and an accent-bright newspaper glyph that lifts to
/// [EditorialMonoclePalette.accentBright] while the feed is open. The
/// unread-count badge resolves to the canonical [EditorialMonoclePalette.danger]
/// token (dark warm-red), not the legacy Material `Colors.redAccent`.
///
/// All colours resolve from [EditorialMonoclePalette] tokens (issue #2858);
/// no hard-coded hex literals. SPEC: `SPEC/ui/player-turn-event-feed.md`.
class PlayerTurnEventsFeedToggleButton extends StatelessWidget {
  const PlayerTurnEventsFeedToggleButton({
    super.key,
    required this.eventCount,
    required this.tooltip,
    required this.showFeed,
    required this.onPressed,
  });

  final int eventCount;
  final String tooltip;
  final bool showFeed;
  final VoidCallback onPressed;

  /// Side length of the tappable toggle surface inside the 34 dp tab bar.
  /// Sits just under `kMinInteractiveDimension` (48) per Material guidance
  /// but the parent `Tooltip` keeps the hover/focus affordance accessible
  /// and the surrounding tab bar contributes the 4 dp gap so the visual
  /// hit target reads as 34 dp — matching the cargo/treasury cells.
  static const double surfaceSize = 28;

  /// Side length of the newspaper glyph painted inside the toggle.
  static const double glyphSize = 20;

  /// Min height/width of the unread-count badge (sized for "99+").
  static const double badgeMinExtent = 16;

  /// Outer alpha of the badge background (so very dim chrome behind it
  /// still reads, but the badge sits brightly forward).
  static const double badgeBackgroundAlpha = 0.95;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = showFeed
        ? EditorialMonoclePalette.accentBright
        : EditorialMonoclePalette.accent;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: kPlayerTurnFeedToggleButtonKey,
          onTap: onPressed,
          customBorder: const StadiumBorder(),
          child: SizedBox(
            width: surfaceSize,
            height: surfaceSize,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: <Widget>[
                Icon(
                  showFeed ? Icons.newspaper : Icons.newspaper_outlined,
                  size: glyphSize,
                  color: iconColor,
                ),
                Positioned(
                  right: -4,
                  top: -2,
                  child: _UnreadBadge(count: eventCount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small pill that renders the number of unread feed entries beside the
/// newspaper glyph. Background resolves to the canonical
/// [EditorialMonoclePalette.danger] token; foreground resolves to the
/// canonical [EditorialMonoclePalette.bg] token so the chip reads as
/// "engraved" against the dim chrome.
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final String label = count > 99 ? '99+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: EditorialMonoclePalette.danger.withValues(
          alpha: PlayerTurnEventsFeedToggleButton.badgeBackgroundAlpha,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      constraints: const BoxConstraints(
        minHeight: PlayerTurnEventsFeedToggleButton.badgeMinExtent,
        minWidth: PlayerTurnEventsFeedToggleButton.badgeMinExtent,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: EditorialMonoclePalette.bg,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Floating, scrollable news card rendered on the in-game map stack when
/// the player toggles the newspaper button in [GameTabBar].
///
/// Implements `Refs #2861` S7 dark editorial-monocle restyle: the legacy
/// near-black Material box is replaced with a token-resolved
/// `surface → bg` gradient (per [CtGradients.panelGradient]) framed by a
/// 1 dp [EditorialMonoclePalette.accentDim] brass border, matching the
/// floating chrome family used by `GameMapPlayersBar`, the empire left
/// rail, and the side menu. The card never displays an `Events` title row
/// (per `SPEC/ui/player-turn-event-feed.md` § Acceptance criteria); the
/// header slot is reserved for empty-state copy and event entries only.
///
/// All colours resolve from [EditorialMonoclePalette] tokens (issue #2858);
/// no hard-coded hex literals. SPEC: `SPEC/ui/player-turn-event-feed.md`.
class PlayerTurnEventFeedCard extends StatelessWidget {
  const PlayerTurnEventFeedCard({
    super.key,
    required this.entries,
    required this.emptyLabel,
  });

  final List<PlayerTurnEventFeedEntry> entries;
  final String emptyLabel;

  /// Card border thickness (brass strip width). Matches the 1 dp border
  /// used by `GameMapPlayersBar._PlayerChip` for visual cohesion.
  static const double borderWidth = 1;

  /// Outer padding inside the card frame (mockup parity with the legacy
  /// 10 px content inset).
  static const EdgeInsetsGeometry contentPadding = EdgeInsets.all(10);

  /// Max content height inside the scroll viewport so the card never grows
  /// taller than ~½ of the wide map stack (parity with the legacy 220 px
  /// cap that consumers depended on for layout flow).
  static const double maxContentHeight = 220;

  /// Vertical gap between consecutive event rows inside the scroll
  /// viewport (matches the legacy `ListView.separated` cadence).
  static const double rowGap = 6;

  /// Inner vertical padding for tappable rows so the press-state highlight
  /// reads as a tap target without overflowing adjacent rows.
  static const double tappableRowVerticalPadding = 2;

  /// Stable key consumers / tests can use to find the framed surface
  /// inside the floating card (parity with sibling chrome keys such as
  /// `GameTabBar.surfaceKey`).
  static const Key surfaceKey = Key('player_turn_event_feed_card_surface');

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
    return SizedBox(
      width: kGameMapWideProvinceSidePanelWidth,
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
                : _FeedEntriesList(entries: entries, bodyStyle: bodyStyle),
          ),
        ),
      ),
    );
  }
}

/// Internal list that renders feed rows with shared dark-theme text style
/// and a tap-down highlight for entries that resolve a map anchor.
class _FeedEntriesList extends StatelessWidget {
  const _FeedEntriesList({required this.entries, required this.bodyStyle});

  final List<PlayerTurnEventFeedEntry> entries;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: entries.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: PlayerTurnEventFeedCard.rowGap),
      itemBuilder: (BuildContext context, int index) {
        final PlayerTurnEventFeedEntry entry = entries[index];
        final Widget text = Text(entry.text, style: bodyStyle);
        if (entry.onTap == null) {
          return text;
        }
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: entry.onTap,
            splashColor: EditorialMonoclePalette.surfaceLite,
            highlightColor: EditorialMonoclePalette.surfaceLite,
            hoverColor: EditorialMonoclePalette.surfaceLite,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: PlayerTurnEventFeedCard.tappableRowVerticalPadding,
              ),
              child: text,
            ),
          ),
        );
      },
    );
  }
}
