import 'package:flutter/material.dart';

import '../../../../config/editorial_monocle_palette.dart';
import '../../flame/game_screen_shared.dart' show kPlayersBarToggleButtonKey;

/// Toggle for the in-game Great Power players bar; lives in the trailing
/// cluster of [GameTabBar] immediately left of the news toggle.
///
/// Chrome matches [PlayerTurnEventsFeedToggleButton] (28 × 22 dp bordered
/// surface). SPEC: `SPEC/ui/empire-overview.md` § Players bar toggle.
class PlayersBarToggleButton extends StatefulWidget {
  const PlayersBarToggleButton({
    super.key,
    required this.tooltip,
    required this.showPlayersBar,
    required this.onPressed,
  });

  final String tooltip;
  final bool showPlayersBar;
  final VoidCallback onPressed;

  static const double surfaceWidth = 28;
  static const double surfaceHeight = 22;
  static const double glyphSize = 14;
  static const double borderWidth = 1;

  @override
  State<PlayersBarToggleButton> createState() => _PlayersBarToggleButtonState();
}

class _PlayersBarToggleButtonState extends State<PlayersBarToggleButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.showPlayersBar;
    final glyphColor = active
        ? EditorialMonoclePalette.accent
        : (_hovering
              ? EditorialMonoclePalette.accentBright
              : EditorialMonoclePalette.accentDim);
    final borderColor = (active || _hovering)
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
            key: kPlayersBarToggleButtonKey,
            onTap: widget.onPressed,
            child: Container(
              width: PlayersBarToggleButton.surfaceWidth,
              height: PlayersBarToggleButton.surfaceHeight,
              decoration: BoxDecoration(
                color: EditorialMonoclePalette.bgDeep,
                border: Border.all(
                  color: borderColor,
                  width: PlayersBarToggleButton.borderWidth,
                ),
              ),
              child: Center(
                child: PlayersBarGlyph(
                  size: PlayersBarToggleButton.glyphSize,
                  color: glyphColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Monochrome vector glyph: three stacked horizontal chip bars.
class PlayersBarGlyph extends StatelessWidget {
  const PlayersBarGlyph({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _PlayersBarGlyphPainter(color: color),
    );
  }
}

class _PlayersBarGlyphPainter extends CustomPainter {
  const _PlayersBarGlyphPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final barHeight = size.height * 0.18;
    final gap = size.height * 0.12;
    final barWidth = size.width * 0.85;
    final left = (size.width - barWidth) / 2;
    var top = size.height * 0.12;
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(Rect.fromLTWH(left, top, barWidth, barHeight), paint);
      top += barHeight + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _PlayersBarGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}
