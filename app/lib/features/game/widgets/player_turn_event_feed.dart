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

/// Newspaper toggle for the human-player turn event feed; lives in the
/// trailing slot of [GameTabBar].
///
/// Implements `Refs #2861` M3 mockup-fidelity chrome (mockup `.news-toggle`
/// in `SPEC/ui/mockups/GAME10001-game-screen.html`): a bordered
/// `28 × 22` dp surface filled with [EditorialMonoclePalette.bgDeep] behind a
/// `1` dp [EditorialMonoclePalette.border] outline (lifting to
/// [EditorialMonoclePalette.accentDim] on hover/open). The glyph is a
/// `14 × 14` dp monochrome [NewspaperGlyph] vector (the mockup `.news-toggle
/// svg`, **not** a Material `Icons.newspaper` at 20 dp), tinted via
/// `currentColor` semantics: [EditorialMonoclePalette.accentDim] closed,
/// [EditorialMonoclePalette.accentBright] on hover, and
/// [EditorialMonoclePalette.accent] while the feed is open.
///
/// The unread-count badge resolves to the canonical
/// [EditorialMonoclePalette.danger] token (dark warm-red), positioned per the
/// mockup `.news-badge` (`top: -4`, `right: -6`), not the legacy Material
/// `Colors.redAccent`.
///
/// All colours resolve from [EditorialMonoclePalette] tokens (issue #2858);
/// no hard-coded hex literals. SPEC: `SPEC/ui/player-turn-event-feed.md`.
class PlayerTurnEventsFeedToggleButton extends StatefulWidget {
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

  /// Width of the toggle surface (mockup `.news-toggle { width: 28px }`).
  static const double surfaceWidth = 28;

  /// Height of the toggle surface (mockup `.news-toggle { height: 22px }`).
  static const double surfaceHeight = 22;

  /// Side length of the newspaper glyph painted inside the toggle
  /// (mockup `.news-toggle svg { width: 14px; height: 14px }`).
  static const double glyphSize = 14;

  /// Border thickness around the toggle surface
  /// (mockup `.news-toggle { border: 1px solid var(--border) }`).
  static const double borderWidth = 1;

  /// Min height/width of the unread-count badge (sized for "99+").
  static const double badgeMinExtent = 16;

  /// Outer alpha of the badge background (so very dim chrome behind it
  /// still reads, but the badge sits brightly forward).
  static const double badgeBackgroundAlpha = 0.95;

  @override
  State<PlayerTurnEventsFeedToggleButton> createState() =>
      _PlayerTurnEventsFeedToggleButtonState();
}

class _PlayerTurnEventsFeedToggleButtonState
    extends State<PlayerTurnEventsFeedToggleButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.showFeed;
    final Color glyphColor = active
        ? EditorialMonoclePalette.accent
        : (_hovering
              ? EditorialMonoclePalette.accentBright
              : EditorialMonoclePalette.accentDim);
    final Color borderColor = (active || _hovering)
        ? EditorialMonoclePalette.accentDim
        : EditorialMonoclePalette.border;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: kPlayerTurnFeedToggleButtonKey,
            onTap: widget.onPressed,
            child: Container(
              width: PlayerTurnEventsFeedToggleButton.surfaceWidth,
              height: PlayerTurnEventsFeedToggleButton.surfaceHeight,
              decoration: BoxDecoration(
                color: EditorialMonoclePalette.bgDeep,
                border: Border.all(
                  color: borderColor,
                  width: PlayerTurnEventsFeedToggleButton.borderWidth,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: <Widget>[
                  NewspaperGlyph(
                    size: PlayerTurnEventsFeedToggleButton.glyphSize,
                    color: glyphColor,
                  ),
                  Positioned(
                    right: -6,
                    top: -4,
                    child: _UnreadBadge(count: widget.eventCount),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Monochrome newspaper glyph painted as a small vector so it tints via a
/// single `currentColor`-style [color] (mockup `.news-toggle svg`). Used
/// instead of a Material `Icons.newspaper` so the toggle can render the
/// `14 × 14` dp mockup glyph at the exact accent-dim/accent state colours
/// (issue #2861 M3).
class NewspaperGlyph extends StatelessWidget {
  const NewspaperGlyph({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _NewspaperGlyphPainter(color),
    );
  }
}

class _NewspaperGlyphPainter extends CustomPainter {
  const _NewspaperGlyphPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w / 14).clamp(1.0, 2.0);
    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Outer page frame.
    final Rect page = Rect.fromLTWH(
      w * 0.10,
      h * 0.14,
      w * 0.80,
      h * 0.72,
    );
    canvas.drawRect(page, stroke);

    // Masthead bar (filled title block).
    canvas.drawRect(
      Rect.fromLTWH(page.left + w * 0.10, page.top + h * 0.10, w * 0.60, h * 0.12),
      fill,
    );

    // Column text lines.
    final double lineLeft = page.left + w * 0.10;
    final double lineRight = page.right - w * 0.10;
    for (int i = 0; i < 3; i++) {
      final double y = page.top + h * (0.34 + i * 0.16);
      canvas.drawLine(Offset(lineLeft, y), Offset(lineRight, y), stroke);
    }
  }

  @override
  bool shouldRepaint(_NewspaperGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
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
