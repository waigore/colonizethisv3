part of 'player_turn_event_feed.dart';

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
