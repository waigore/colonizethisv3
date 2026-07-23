// Main-menu `pixelArt` buttons-region scroll-bracket widgets and painter,
// split out from `main_menu.dart` to keep the host file under the repo-lint
// non-comment line limit per
// `SPEC/program/dart-file-non-comment-line-size.md`.
//
// All classes here are library-private (`_PixelArtButtonsRegion`,
// `_PixelArtScrollBracket`, `_PixelArtScrollBracketPainter`) and consumed only
// by the main-menu buttons region inside the parent library; they continue to
// reference the `kMainMenuScrollBracket*` constants declared in the host file.

part of 'main_menu.dart';

/// Side enumeration for a [_PixelArtScrollBracket]. Encodes which gutter
/// (left or right of the buttons region) the bracket flanks; controls the
/// horizontal offset direction of the ornamental dots and the canonical
/// stable `Key` value applied to the bracket widget so widget tests can
/// distinguish the two bracket positions independently.
enum _ScrollBracketSide { left, right }

/// Buttons-region wrapper for the `pixelArt` main-menu variant.
///
/// Stacks the wood-panel button column under two ornamental
/// [_PixelArtScrollBracket]s positioned [kMainMenuScrollBracketGutter]
/// logical pixels outside the left and right edges of the column. The
/// brackets paint across the middle
/// `1 - 2 * kMainMenuScrollBracketVerticalInset` of the column height per
/// `SPEC/ui/main-menu.md` § Buttons region and mockup
/// `.buttons-region::before` / `::after` rules. `Clip.none` lets the
/// brackets render outside the column bounds without being clipped by the
/// outer scroll view.
class _PixelArtButtonsRegion extends StatelessWidget {
  const _PixelArtButtonsRegion({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        child,
        Positioned(
          left: -kMainMenuScrollBracketGutter - kMainMenuScrollBracketWidth / 2,
          top: 0,
          bottom: 0,
          width: kMainMenuScrollBracketWidth,
          child: const _PixelArtScrollBracket(
            key: Key(kMainMenuScrollBracketLeftKey),
            side: _ScrollBracketSide.left,
          ),
        ),
        Positioned(
          right:
              -kMainMenuScrollBracketGutter - kMainMenuScrollBracketWidth / 2,
          top: 0,
          bottom: 0,
          width: kMainMenuScrollBracketWidth,
          child: const _PixelArtScrollBracket(
            key: Key(kMainMenuScrollBracketRightKey),
            side: _ScrollBracketSide.right,
          ),
        ),
      ],
    );
  }
}

/// Ornamental scroll bracket flanking the `pixelArt` buttons region.
///
/// Renders a narrow vertical gradient bar (`--accent-dim` → `--accent` →
/// `--accent-dim`, transparent at both ends) plus a single ornamental dot
/// above and below the bar, all painted at [kMainMenuScrollBracketOpacity]
/// per `SPEC/ui/main-menu.md` § Buttons region and mockup
/// `.buttons-region::before` / `::after` rules. The bar is vertically
/// centered within its parent and spans the middle
/// `1 - 2 * kMainMenuScrollBracketVerticalInset` fraction of the parent
/// height; the [side] discriminator flips the ornamental-dot horizontal
/// offset so the dots align with the corresponding mockup `box-shadow`
/// direction (`-2px` for left, `+2px` for right).
class _PixelArtScrollBracket extends StatelessWidget {
  const _PixelArtScrollBracket({super.key, required this.side});

  final _ScrollBracketSide side;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: kMainMenuScrollBracketOpacity,
      child: CustomPaint(
        painter: _PixelArtScrollBracketPainter(
          side: side,
          accent: EditorialMonoclePalette.accent,
          accentDim: EditorialMonoclePalette.accentDim,
        ),
      ),
    );
  }
}

class _PixelArtScrollBracketPainter extends CustomPainter {
  _PixelArtScrollBracketPainter({
    required this.side,
    required this.accent,
    required this.accentDim,
  });

  final _ScrollBracketSide side;
  final Color accent;
  final Color accentDim;

  static const double _barCornerRadius = 2;
  static const double _dotSize = 2;
  // Mockup `box-shadow: ±2px 6px 0 -1px var(--accent-dim)` — the 6px
  // vertical offset measures from the bar's top/bottom edge outward.
  static const double _dotVerticalOffsetFromBarEdge = 6;
  // Horizontal mockup offset is ±2px from the bar's centerline.
  static const double _dotHorizontalOffsetFromCenter = 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final double inset = size.height * kMainMenuScrollBracketVerticalInset;
    final double barTop = inset;
    final double barBottom = size.height - inset;
    if (barBottom <= barTop) return;

    final Rect barRect = Rect.fromLTRB(0, barTop, size.width, barBottom);
    final RRect barRRect = RRect.fromRectAndRadius(
      barRect,
      const Radius.circular(_barCornerRadius),
    );
    final Paint barPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          accentDim.withValues(alpha: 0),
          accentDim,
          accent,
          accentDim,
          accentDim.withValues(alpha: 0),
        ],
        stops: const <double>[0.0, 0.08, 0.5, 0.92, 1.0],
      ).createShader(barRect);
    canvas.drawRRect(barRRect, barPaint);

    final Paint dotPaint = Paint()..color = accentDim;
    final double horizontalOffset = side == _ScrollBracketSide.left
        ? -_dotHorizontalOffsetFromCenter
        : _dotHorizontalOffsetFromCenter;
    final double dotX = size.width / 2 + horizontalOffset;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(dotX, barTop - _dotVerticalOffsetFromBarEdge),
        width: _dotSize,
        height: _dotSize,
      ),
      dotPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(dotX, barBottom + _dotVerticalOffsetFromBarEdge),
        width: _dotSize,
        height: _dotSize,
      ),
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PixelArtScrollBracketPainter oldDelegate) {
    return oldDelegate.side != side ||
        oldDelegate.accent != accent ||
        oldDelegate.accentDim != accentDim;
  }
}
