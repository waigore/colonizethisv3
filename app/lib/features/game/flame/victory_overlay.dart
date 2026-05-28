import 'package:flutter/material.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../../../config/editorial_monocle_palette.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_brass_divider.dart';
import '../../../widgets/ct_gradients.dart';
import '../../../widgets/ct_nine_patch_button.dart';

/// Stateful overlay so "View final state" can hide the panel without a route (SPEC/game/victory.md).
///
/// Visual contract: SPEC/ui/victory-overlay.md — dark `--dialog-scrim` wash,
/// centered brass-bordered [VictoryPanel] with laurel decoration, brass
/// divider, and asymmetric corner brackets.
class VictoryOverlay extends StatefulWidget {
  const VictoryOverlay({
    required this.game,
    required this.victory,
    required this.bus,
    super.key,
  });

  /// SPEC/ui/victory-overlay.md — [UiScreenIds.victoryOverlay].
  static const screenId = UiScreenIds.victoryOverlay;

  final ct_models.Game game;
  final ct_models.VictoryState victory;
  final ct_models.AppEventBus bus;

  @override
  State<VictoryOverlay> createState() => _VictoryOverlayState();
}

class _VictoryOverlayState extends State<VictoryOverlay> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    return Positioned.fill(
      child: Container(
        color: EditorialMonoclePalette.dialogScrim,
        child: Center(
          child: VictoryPanel(
            game: widget.game,
            victory: widget.victory,
            bus: widget.bus,
            onViewFinalState: () => setState(() => _dismissed = true),
          ),
        ),
      ),
    );
  }
}

/// Brass-bordered ceremonial panel for the military victory overlay.
///
/// Visual contract: SPEC/ui/victory-overlay.md and the OVL20001 mockup.
/// Renders the laurel decoration row, the localized victory-type label, a
/// [CtBrassDivider], the winner sentence, and two action buttons inside a
/// `surface-lite → bg-deep` gradient surface with a 2px `--accent` border
/// and asymmetric corner brackets.
class VictoryPanel extends StatelessWidget {
  const VictoryPanel({
    required this.game,
    required this.victory,
    required this.bus,
    this.onViewFinalState,
    super.key,
  });

  final ct_models.Game game;
  final ct_models.VictoryState victory;
  final ct_models.AppEventBus bus;
  final VoidCallback? onViewFinalState;

  /// Outer max width for the ceremonial panel. Matches the mockup's
  /// `clamp(280px,88vw,460px)` ceiling so the panel does not stretch to the
  /// full overlay width on wide viewports.
  @visibleForTesting
  static const double maxWidth = 460;

  /// Border thickness for the surrounding `--accent` frame.
  static const double borderWidth = 2;

  /// Corner-bracket dimensions for the top-left / bottom-right ornaments.
  static const double cornerBracketWidth = 20;
  static const double cornerBracketHeight = 24;
  static const double cornerBracketInset = 4;
  static const double cornerBracketStroke = 1.5;
  static const double cornerBracketAlpha = 0.7;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Stack(
          children: <Widget>[
            _buildPanelSurface(context),
            const Positioned(
              top: cornerBracketInset,
              left: cornerBracketInset,
              child: _VictoryCornerBracket(corner: _CornerSide.topLeft),
            ),
            const Positioned(
              bottom: cornerBracketInset,
              right: cornerBracketInset,
              child: _VictoryCornerBracket(corner: _CornerSide.bottomRight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelSurface(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: CtGradients.victoryPanelGradient,
        border: Border.all(
          color: EditorialMonoclePalette.accent,
          width: borderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        child: _buildPanelColumn(context),
      ),
    );
  }

  Widget _buildPanelColumn(BuildContext context) {
    final l10n = appL10n(context);
    final ct_models.Player winner =
        game.playerById(victory.winnerPlayerId) ?? game.players.first;
    final String victoryLabel = switch (victory.type) {
      ct_models.VictoryType.military => l10n.victory_military,
    };
    final ThemeData theme = Theme.of(context);
    final TextStyle? titleStyle = theme.textTheme.headlineSmall?.copyWith(
      color: EditorialMonoclePalette.accent,
      letterSpacing: 1.2,
      fontWeight: FontWeight.w700,
    );
    final TextStyle? bodyStyle = theme.textTheme.bodyLarge?.copyWith(
      color: EditorialMonoclePalette.fg,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const _VictoryLaurelRow(),
        const SizedBox(height: 10),
        Text(
          victoryLabel.toUpperCase(),
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const CtBrassDivider(),
        const SizedBox(height: 14),
        Text(
          l10n.victory_winnerOnTurn(winner.displayName, victory.turnNumber),
          style: bodyStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildActionRow(context, l10n),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context, AppLocalizations l10n) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? secondaryButtonStyle = theme.textTheme.titleSmall?.copyWith(
      color: EditorialMonoclePalette.muted,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: <Widget>[
        CtNinePatchButton(
          onPressed: () => bus.emit(const ct_models.NavigateToShellEvent()),
          child: Text(l10n.victory_returnToMainMenu),
        ),
        CtNinePatchButton(
          onPressed: () {
            onViewFinalState?.call();
          },
          child: Text(
            l10n.victory_viewFinalState,
            style: secondaryButtonStyle,
          ),
        ),
      ],
    );
  }
}

/// Three-glyph laurel decoration sitting above the victory-type label. Uses
/// Unicode glyphs in `--accent` at 0.6 alpha (no asset dependency).
class _VictoryLaurelRow extends StatelessWidget {
  const _VictoryLaurelRow();

  @override
  Widget build(BuildContext context) {
    final TextStyle laurelStyle = TextStyle(
      color: EditorialMonoclePalette.accent.withValues(alpha: 0.6),
      fontSize: 28,
      height: 1,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text('\u269C', style: laurelStyle),
        const SizedBox(width: 6),
        Text('\u2605', style: laurelStyle),
        const SizedBox(width: 6),
        Text('\u269C', style: laurelStyle),
      ],
    );
  }
}

enum _CornerSide { topLeft, bottomRight }

/// Asymmetric corner-bracket ornament drawn for the top-left and
/// bottom-right corners of the victory panel surface. Renders a 1.5px brass
/// L-shape at `cornerBracketAlpha` opacity.
class _VictoryCornerBracket extends StatelessWidget {
  const _VictoryCornerBracket({required this.corner});

  final _CornerSide corner;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: VictoryPanel.cornerBracketWidth,
      height: VictoryPanel.cornerBracketHeight,
      child: CustomPaint(
        painter: _VictoryCornerBracketPainter(
          color: EditorialMonoclePalette.accent.withValues(
            alpha: VictoryPanel.cornerBracketAlpha,
          ),
          stroke: VictoryPanel.cornerBracketStroke,
          corner: corner,
        ),
      ),
    );
  }
}

class _VictoryCornerBracketPainter extends CustomPainter {
  _VictoryCornerBracketPainter({
    required this.color,
    required this.stroke,
    required this.corner,
  });

  final Color color;
  final double stroke;
  final _CornerSide corner;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke;

    final double half = stroke / 2;
    switch (corner) {
      case _CornerSide.topLeft:
        // Top edge then left edge.
        canvas.drawLine(
          Offset(0, half),
          Offset(size.width, half),
          paint,
        );
        canvas.drawLine(
          Offset(half, 0),
          Offset(half, size.height),
          paint,
        );
        break;
      case _CornerSide.bottomRight:
        // Bottom edge then right edge.
        canvas.drawLine(
          Offset(0, size.height - half),
          Offset(size.width, size.height - half),
          paint,
        );
        canvas.drawLine(
          Offset(size.width - half, 0),
          Offset(size.width - half, size.height),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(_VictoryCornerBracketPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.stroke != stroke ||
        oldDelegate.corner != corner;
  }
}
