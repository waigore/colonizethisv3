import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../../../../config/constants.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';
import '../../../../widgets/ct_gradients.dart';
import '../../../../widgets/ct_spacing.dart';

import 'victory_overlay_panel_actions.dart';
import 'victory_overlay_panel_corners.dart';

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

  /// Laurel font size (logical px) at default and narrow viewport widths.
  /// Pinned to the lower bound of the mockup's `clamp(24px,5vw,36px)` so the
  /// narrow flip lands on the same value the mockup hits at small widths.
  /// SPEC/ui/victory-overlay.md § Narrow viewport.
  static const double laurelFontSizeWide = 28;
  static const double laurelFontSizeNarrow = 24;

  @override
  Widget build(BuildContext context) {
    final bool narrow =
        MediaQuery.sizeOf(context).width < kNarrowBreakpoint;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: Padding(
        padding: const EdgeInsets.all(CtSpacing.xxl),
        child: Stack(
          children: <Widget>[
            _buildPanelSurface(context, narrow: narrow),
            const Positioned(
              top: cornerBracketInset,
              left: cornerBracketInset,
              child: VictoryCornerBracket.topLeft(),
            ),
            const Positioned(
              bottom: cornerBracketInset,
              right: cornerBracketInset,
              child: VictoryCornerBracket.bottomRight(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelSurface(BuildContext context, {required bool narrow}) {
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
        child: _buildPanelColumn(context, narrow: narrow),
      ),
    );
  }

  Widget _buildPanelColumn(BuildContext context, {required bool narrow}) {
    final l10n = appL10n(context);
    final ct_models.Player winner =
        game.playerById(victory.winnerPlayerId) ?? game.players.first;
    final String victoryLabel = switch (victory.type) {
      ct_models.VictoryType.military => l10n.victory_military,
    };
    final ThemeData theme = Theme.of(context);
    final TextStyle? titleBase =
        narrow ? theme.textTheme.titleMedium : theme.textTheme.headlineSmall;
    final TextStyle? titleStyle = titleBase?.copyWith(
      color: EditorialMonoclePalette.accent,
      letterSpacing: 1.2,
      fontWeight: FontWeight.w700,
    );
    final TextStyle? bodyBase =
        narrow ? theme.textTheme.bodyMedium : theme.textTheme.bodyLarge;
    final TextStyle? bodyStyle = bodyBase?.copyWith(
      color: EditorialMonoclePalette.fg,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        VictoryLaurelRow(narrow: narrow),
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
        buildVictoryPanelActionRow(this, context, l10n, narrow: narrow),
      ],
    );
  }
}
