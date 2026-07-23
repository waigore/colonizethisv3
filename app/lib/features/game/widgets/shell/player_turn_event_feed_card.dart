// Floating player turn event feed card on the in-game map stack.
//
// De-parted wave-9 cluster (Refs #4117).

import 'package:flutter/material.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';

import '../../../../widgets/ct_gradients.dart';
import '../../screens/game/game_screen_shared.dart'
    show kGameMapWideProvinceSidePanelWidth;
import 'player_turn_event_feed_types.dart';

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
/// Wide layout (default, `narrow: false`): card width is
/// [kGameMapWideProvinceSidePanelWidth] (320 dp), so the card and the
/// open province side panel never sit side-by-side without the wide
/// inset (issue #2861 S7).
///
/// Narrow layout (issue #2870 S3 / Req 11, `MediaQuery.size.width <
/// kNarrowBreakpoint`): host constructs the card with `narrow: true`.
/// The card width then resolves to
/// `clamp(narrowMinWidth, viewport.width / 2, narrowMaxWidth)` dp,
/// mirroring the mockup `.news-feed-card @media (max-width:600px)
/// { width:clamp(180px, 50vw, 260px); }` rule from
/// `SPEC/ui/mockups/GAME10001-game-screen.html`. The province bottom
/// sheet covers the card from the bottom on narrow, so no wide
/// side-panel inset applies.
///
/// All colours resolve from [EditorialMonoclePalette] tokens (issue #2858);
/// no hard-coded hex literals. SPEC: `SPEC/ui/player-turn-event-feed.md`.
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
  /// The width resolves to
  /// `clamp(narrowMinWidth, viewport.width / 2, narrowMaxWidth)` dp.
  final bool narrow;

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

  /// Lower bound for the narrow-layout card width
  /// (mockup `clamp(180px, 50vw, 260px)` lower bound).
  static const double narrowMinWidth = 180;

  /// Upper bound for the narrow-layout card width
  /// (mockup `clamp(180px, 50vw, 260px)` upper bound).
  static const double narrowMaxWidth = 260;

  /// Multiplier applied to viewport width to derive the narrow card width
  /// inside the [narrowMinWidth] – [narrowMaxWidth] envelope (mockup
  /// `50vw` term).
  static const double narrowViewportFraction = 0.5;

  /// Stable key consumers / tests can use to find the framed surface
  /// inside the floating card (parity with sibling chrome keys such as
  /// `GameTabBar.surfaceKey`).
  static const Key surfaceKey = Key('player_turn_event_feed_card_surface');

  /// Resolves the narrow-layout card width for a given viewport width
  /// per the mockup `clamp(180px, 50vw, 260px)` rule. Exposed for
  /// widget-test pinning so the contract stays in step with the SPEC.
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
