part of 'player_turn_event_feed.dart';

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
